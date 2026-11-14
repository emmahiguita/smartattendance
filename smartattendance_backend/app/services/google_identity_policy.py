"""Valida autoridad del correo después de verificar firma, audiencia y emisor."""
from fastapi import HTTPException


def account_email(claims: dict) -> str:
    email = claims.get('email')
    subject = claims.get('sub')
    verified = claims.get('email_verified') is True
    if not isinstance(email, str) or not isinstance(subject, str) or not subject.strip() or not verified:
        raise HTTPException(status_code=401, detail='Google no acredita un correo verificado para esta cuenta.')
    email = email.strip().lower()
    local, separator, domain = email.partition('@')
    hosted = claims.get('hd')
    authoritative = domain == 'gmail.com' or (
        isinstance(hosted, str) and bool(hosted.strip()) and hosted.strip().lower() == domain)
    if not local or not separator or '@' in domain or not authoritative:
        raise HTTPException(status_code=401, detail='Usa tu contraseña; este correo requiere una vinculación de identidad adicional.')
    return email
