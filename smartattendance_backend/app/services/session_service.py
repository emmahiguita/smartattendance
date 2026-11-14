"""Emisión y rotación atómica de sesiones sobre la base real de la API."""
import hashlib
import time
import uuid
from sqlalchemy import update, select, delete
from fastapi import HTTPException
from app.models.auth_state import AuthSession
from app.models.user import User
from app.core.config import settings
from app.core.security import create_access_token, create_refresh_token, decode_refresh_token


def digest(token):
    return hashlib.sha256(token.encode()).hexdigest()


def lock_credentials(db, user):
    # UPDATE condicional obtiene el mismo bloqueo por usuario en SQLite/PostgreSQL.
    # La credencial validada debe seguir siendo la actual dentro de la transacción.
    result = db.execute(update(User).where(User.id == user.id, User.is_active.is_(True),
        User.hashed_password == user.hashed_password)
        .values(hashed_password=User.hashed_password).execution_options(synchronize_session=False))
    if result.rowcount != 1:
        db.rollback()
        raise HTTPException(status_code=401, detail='Las credenciales cambiaron; inicia sesión de nuevo.')


def issue(db, user):
    lock_credentials(db, user)
    db.execute(delete(AuthSession).where(AuthSession.expires_at <= time.time()))
    sid = str(uuid.uuid4())
    refresh = create_refresh_token({'sub': str(user.id), 'sid': sid})
    db.add(AuthSession(id=sid, user_id=user.id, refresh_digest=digest(refresh),
        expires_at=time.time()+settings.REFRESH_TOKEN_EXPIRE_DAYS*86400, revoked=False))
    db.commit()
    return create_access_token({'sub': str(user.id), 'cedula': user.cedula, 'sid': sid}), refresh


def rotate(db, user, token, claims):
    sid = claims.get('sid')
    if not isinstance(sid, str):
        raise HTTPException(status_code=401, detail='Inicia sesión de nuevo para renovar tus credenciales.')
    refresh = create_refresh_token({'sub': str(user.id), 'sid': sid})
    result = db.execute(update(AuthSession).where(AuthSession.id == sid,
        AuthSession.user_id == user.id, AuthSession.revoked.is_(False),
        AuthSession.expires_at > time.time(), AuthSession.refresh_digest == digest(token))
        .values(refresh_digest=digest(refresh),
                expires_at=time.time()+settings.REFRESH_TOKEN_EXPIRE_DAYS*86400))
    if result.rowcount != 1:
        db.rollback()
        raise HTTPException(status_code=401, detail='La sesión expiró o el refresco ya fue utilizado.')
    db.commit()
    return create_access_token({'sub': str(user.id), 'cedula': user.cedula, 'sid': sid}), refresh


def check_access(db, user_id, claims):
    sid = claims.get('sid')
    # Compatibilidad acotada: accesos anteriores expiran con su JWT original.
    if sid is None:
        return
    session = db.scalar(select(AuthSession).where(AuthSession.id == sid,
        AuthSession.user_id == user_id, AuthSession.revoked.is_(False),
        AuthSession.expires_at > time.time()))
    if session is None:
        raise HTTPException(status_code=401, detail='Sesión revocada o expirada.')


def revoke_user(db, user_id):
    db.execute(update(AuthSession).where(AuthSession.user_id == user_id).values(revoked=True))


def revoke_session(db, refresh_token):
    """Revoca solo el sid firmado, incluso si su refresco acaba de rotar."""
    claims = decode_refresh_token(refresh_token)
    sid, subject = claims.get('sid'), claims.get('sub')
    if not isinstance(sid, str) or not isinstance(subject, str) or not subject.isascii() or not subject.isdecimal():
        raise HTTPException(status_code=401, detail='La credencial no identifica una sesión revocable.')
    db.execute(update(AuthSession).where(AuthSession.id == sid,
        AuthSession.user_id == int(subject)).values(revoked=True))
    db.commit()
