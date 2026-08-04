# app/core/security.py
"""
JWT creation and verification utilities.
SRP: handles ONLY token generation and validation.
"""
from datetime import datetime, timedelta, timezone
from jose import JWTError, jwt
from fastapi import HTTPException, status

from app.core.config import settings

ACCESS_TOKEN_TYPE = "access"
REFRESH_TOKEN_TYPE = "refresh"


def _create_token(data: dict, expires_delta: timedelta, token_type: str) -> str:
    """Create a signed JWT with an explicit token-type claim."""
    payload = data.copy()
    expire = datetime.now(timezone.utc) + expires_delta
    payload.update({"exp": expire, "type": token_type})
    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_access_token(data: dict) -> str:
    """Create a signed JWT access token (short-lived)."""
    return _create_token(
        data,
        timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
        ACCESS_TOKEN_TYPE,
    )


def create_refresh_token(data: dict) -> str:
    """Create a signed JWT refresh token (long-lived, used only for renewal)."""
    return _create_token(
        data,
        timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        REFRESH_TOKEN_TYPE,
    )


def decode_access_token(token: str) -> dict:
    """Decode and verify a JWT. Raises HTTP 401 on failure.
    Tokens without a `type` claim (legacy, pre-refresh) are accepted as access tokens."""
    payload = _decode(token)
    if payload.get("type") not in (None, ACCESS_TOKEN_TYPE):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return payload


def decode_refresh_token(token: str) -> dict:
    """Decode and verify a refresh token. Raises HTTP 401 on failure."""
    payload = _decode(token)
    if payload.get("type") != REFRESH_TOKEN_TYPE:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de refresco inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return payload


def _decode(token: str) -> dict:
    try:
        return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )
