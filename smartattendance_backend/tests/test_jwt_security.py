"""Pruebas de firma, expiración y separación de tokens de acceso y refresco."""
from datetime import datetime, timedelta, timezone
import jwt
import pytest
from fastapi import HTTPException
from app.core import security
from app.core.config import settings


def test_signed_token_requires_expiration():
    token = jwt.encode({'sub': '1', 'type': 'access'}, settings.SECRET_KEY,
                       algorithm=settings.ALGORITHM)
    with pytest.raises(HTTPException) as error:
        security.decode_access_token(token)
    assert error.value.status_code == 401


def test_tokens_have_separate_purposes():
    access = security.create_access_token({'sub': '1'})
    refresh = security.create_refresh_token({'sub': '1'})
    assert security.decode_access_token(access)['sub'] == '1'
    assert security.decode_refresh_token(refresh)['sub'] == '1'
    with pytest.raises(HTTPException):
        security.decode_access_token(refresh)
    with pytest.raises(HTTPException):
        security.decode_refresh_token(access)


def test_expired_or_unsigned_tokens_are_rejected():
    payload = {'sub': '1', 'exp': datetime.now(timezone.utc) - timedelta(minutes=1)}
    expired = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    unsigned = jwt.encode({'sub': '1', 'exp': 9999999999}, '', algorithm='none')
    for token in (expired, unsigned, expired[:-5]+'aaaaa'):
        with pytest.raises(HTTPException):
            security.decode_access_token(token)
