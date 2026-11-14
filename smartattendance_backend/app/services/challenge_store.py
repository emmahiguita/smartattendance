"""Códigos persistentes con HMAC, expiración y consumo atómico."""
import hashlib
import hmac
import secrets
import time
import uuid
from sqlalchemy import delete, update
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException
from app.core.config import settings
from app.models.auth_state import PasswordChallenge


def key_for(document, email):
    return hashlib.sha256((document.strip()+':'+email.strip().lower()).encode()).hexdigest()


def code_digest(generation, code):
    return hmac.new(settings.SECRET_KEY.encode(), (generation+':'+code).encode(), hashlib.sha256).hexdigest()


def issue(db, document, email):
    key = key_for(document, email)
    code, generation = f'{secrets.randbelow(1000000):06d}', str(uuid.uuid4())
    values = dict(generation=generation, digest=code_digest(generation, code),
                  expires_at=time.time()+600, attempts=0)
    db.execute(delete(PasswordChallenge).where(PasswordChallenge.expires_at <= time.time()))
    result = db.execute(update(PasswordChallenge).where(PasswordChallenge.id == key).values(**values))
    if result.rowcount == 0:
        db.add(PasswordChallenge(id=key, **values))
    try:
        db.commit()
    except IntegrityError as error:
        db.rollback()
        raise HTTPException(status_code=409, detail='Ya existe una solicitud simultánea; vuelve a intentarlo.') from error
    return code, generation


def discard(db, document, email, generation):
    db.execute(delete(PasswordChallenge).where(PasswordChallenge.id == key_for(document, email),
                                              PasswordChallenge.generation == generation))
    db.commit()


def consume(db, document, email, code):
    key = key_for(document, email)
    challenge = db.get(PasswordChallenge, key)
    if challenge is None or challenge.expires_at <= time.time() or challenge.attempts >= 5:
        raise HTTPException(status_code=400, detail='Código inexistente, expirado o bloqueado.')
    conditions = (PasswordChallenge.id == key, PasswordChallenge.generation == challenge.generation,
                  PasswordChallenge.expires_at > time.time(), PasswordChallenge.attempts < 5)
    if not secrets.compare_digest(challenge.digest, code_digest(challenge.generation, code.strip())):
        db.execute(update(PasswordChallenge).where(*conditions).values(attempts=PasswordChallenge.attempts+1))
        db.commit()
        raise HTTPException(status_code=400, detail='Código de verificación inválido.')
    result = db.execute(delete(PasswordChallenge).where(*conditions))
    if result.rowcount != 1:
        db.rollback()
        raise HTTPException(status_code=400, detail='El código ya fue utilizado o bloqueado.')
    # El llamador confirma el consumo junto con el cambio de contraseña.
