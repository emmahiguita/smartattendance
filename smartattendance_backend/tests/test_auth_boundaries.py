"""Regresiones de acceso sin contraseña y escalamiento por registro público."""
import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from app.database.base import Base
from app.models.user import User
from app.models.attendance import Attendance  # registra relación ORM
from app.services.auth_service import AuthService
from app.schemas.user import LoginRequest, RegisterRequest


@pytest.fixture
def database():
    engine = create_engine('sqlite:///:memory:')
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        yield session
    engine.dispose()


def test_passwordless_account_cannot_login(database):
    database.add(User(nombre='QA', apellido='Acceso', cedula='99887766',
                      correo='qa@example.com', cargo='Administrador'))
    database.commit()
    with pytest.raises(HTTPException) as error:
        AuthService(database).login(LoginRequest(cedula='99887766'))
    assert error.value.status_code == 401


def test_public_registration_cannot_choose_admin(database):
    request = RegisterRequest(nombre='QA', apellido='Registro', cedula='99887767',
        correo='qa-register@example.com', password='Password123!', cargo='Administrador')
    with pytest.raises(HTTPException) as error:
        AuthService(database).register(request)
    assert error.value.status_code == 403
    assert database.query(User).count() == 0
