# app/api/v1/deps.py
"""
API dependencies — specifically security and user extraction.
"""
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from pydantic import ValidationError

from app.database.base import get_db
from app.core.security import decode_access_token
from app.repositories.user_repository import UserRepository
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login", auto_error=True)

# Roles with full access to admin endpoints.
# "Desarrollador" NO es admin — es un cargo técnico real (Developer).
ADMIN_ROLES = frozenset({"administrador", "admin"})


def is_admin(user: User) -> bool:
    """True when the user holds an admin role (cargo)."""
    return user.cargo.strip().lower() in ADMIN_ROLES


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """
    Dependency to validate the JWT token and return the current user.
    Raises 401 if invalid token or user not found.
    """
    try:
        payload = decode_access_token(token)
        user_id_str: str = payload.get("sub")
        if user_id_str is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="El token no contiene el ID de usuario",
                headers={"WWW-Authenticate": "Bearer"},
            )
        user_id = int(user_id_str)
    except (ValueError, ValidationError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token con formato inválido",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    repo = UserRepository(db)
    user = repo.get_by_id(user_id)
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="El usuario del token no existe o está inactivo",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return user


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    """Dependency: only admins pass. Enforced server-side, not client trust."""
    if not is_admin(current_user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acceso restringido a administradores.",
        )
    return current_user
