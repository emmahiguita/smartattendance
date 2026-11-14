"""Rotación real contra SQLite: un refresco no puede utilizarse dos veces."""
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from fastapi import HTTPException
import app.models
from app.database.base import Base
from app.models.user import User
from app.core.hashing import hash_password
from app.services.auth_service import AuthService
from app.schemas.user import LoginRequest, RefreshRequest
from app.schemas.user import ResetPasswordRequest
from app.services.challenge_store import issue as issue_code
from app.services.session_service import check_access
from app.services.session_service import issue as issue_session
from app.core.security import decode_access_token
from concurrent.futures import ThreadPoolExecutor


def test_refresh_is_single_use_and_survives_a_new_session(tmp_path):
    engine = create_engine('sqlite:///'+str(tmp_path/'sessions.db'))
    Base.metadata.create_all(engine)
    with Session(engine) as db:
        db.add(User(nombre='QA', apellido='Sesión', cedula='99881122',
            correo='qa-session@example.com', cargo='Empleado',
            hashed_password=hash_password('PruebaSegura9')))
        db.commit()
        tokens = AuthService(db).login(LoginRequest(cedula='99881122', password='PruebaSegura9'))
    with Session(engine) as db:
        rotated = AuthService(db).refresh(RefreshRequest(refresh_token=tokens.refresh_token))
        assert rotated.refresh_token != tokens.refresh_token
    with Session(engine) as db:
        with pytest.raises(HTTPException) as error:
            AuthService(db).refresh(RefreshRequest(refresh_token=tokens.refresh_token))
        assert error.value.status_code == 401
        assert AuthService(db).refresh(RefreshRequest(refresh_token=rotated.refresh_token)).access_token
    engine.dispose()


def test_simultaneous_refresh_has_only_one_winner(tmp_path):
    engine = create_engine('sqlite:///'+str(tmp_path/'parallel.db'))
    Base.metadata.create_all(engine)
    with Session(engine) as db:
        db.add(User(nombre='QA', apellido='Concurrente', cedula='99881124',
            correo='qa-parallel@example.com', cargo='Empleado',
            hashed_password=hash_password('PruebaSegura9')))
        db.commit()
        token = AuthService(db).login(LoginRequest(cedula='99881124', password='PruebaSegura9')).refresh_token
    def renew(_):
        with Session(engine) as db:
            try:
                AuthService(db).refresh(RefreshRequest(refresh_token=token))
                return 200
            except HTTPException as error:
                return error.status_code
    with ThreadPoolExecutor(max_workers=2) as pool:
        assert sorted(pool.map(renew, range(2))) == [200, 401]
    engine.dispose()


def test_stale_verified_credential_cannot_issue_after_reset(tmp_path):
    engine = create_engine('sqlite:///'+str(tmp_path/'stale-login.db'))
    Base.metadata.create_all(engine)
    with Session(engine) as db:
        user = User(nombre='QA', apellido='Carrera', cedula='99881125',
            correo='qa-race@example.com', cargo='Empleado', hashed_password=hash_password('AnteriorSegura9'))
        db.add(user)
        db.commit()
        uid = user.id
        code, _ = issue_code(db, user.cedula, user.correo)
    with Session(engine) as before:
        stale = before.get(User, uid)
        with Session(engine) as reset:
            AuthService(reset).reset_password(ResetPasswordRequest(cedula='99881125',
                correo='qa-race@example.com', code=code, new_password='NuevaSegura9'))
        with pytest.raises(HTTPException) as error:
            issue_session(before, stale)
        assert error.value.status_code == 401
    engine.dispose()


def test_new_auth_tables_preserve_existing_users(tmp_path):
    engine = create_engine('sqlite:///'+str(tmp_path/'upgrade.db'))
    User.__table__.create(engine)
    with Session(engine) as db:
        db.add(User(nombre='Conservar', apellido='Cuenta', cedula='99881126',
                    correo='qa-upgrade@example.com', cargo='Empleado'))
        db.commit()
    Base.metadata.create_all(engine)
    with Session(engine) as db:
        assert db.query(User).one().nombre == 'Conservar'
        assert db.query(User).one().cedula == '99881126'
    engine.dispose()


def test_password_reset_revokes_new_sessions_atomically(tmp_path):
    engine = create_engine('sqlite:///'+str(tmp_path/'reset.db'))
    Base.metadata.create_all(engine)
    with Session(engine) as db:
        user = User(nombre='QA', apellido='Reset', cedula='99881123',
            correo='qa-reset@example.com', cargo='Empleado', hashed_password=hash_password('AnteriorSegura9'))
        db.add(user)
        db.commit()
        auth = AuthService(db)
        old = auth.login(LoginRequest(cedula=user.cedula, password='AnteriorSegura9'))
        code, _ = issue_code(db, user.cedula, user.correo)
        auth.reset_password(ResetPasswordRequest(cedula=user.cedula, correo=user.correo,
                            code=code, new_password='NuevaSegura9'))
        with pytest.raises(HTTPException):
            check_access(db, user.id, decode_access_token(old.access_token))
        with pytest.raises(HTTPException):
            auth.refresh(RefreshRequest(refresh_token=old.refresh_token))
        assert auth.login(LoginRequest(cedula=user.cedula, password='NuevaSegura9')).access_token
    engine.dispose()
