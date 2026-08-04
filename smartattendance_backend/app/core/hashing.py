# app/core/hashing.py
"""
Password hashing utilities (bcrypt directo — passlib 1.7.4 es incompatible
con bcrypt>=4.1 y está sin mantenimiento).
SRP: only password hash/verify lives here.
"""
import bcrypt

# bcrypt trunca a 72 bytes; se aplica límite explícito para evitar ValueError
# en bcrypt>=4.1 con contraseñas largas.
_MAX_BYTES = 72


def hash_password(plain: str) -> str:
    data = plain.encode("utf-8")[:_MAX_BYTES]
    return bcrypt.hashpw(data, bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    data = plain.encode("utf-8")[:_MAX_BYTES]
    try:
        return bcrypt.checkpw(data, hashed.encode("utf-8"))
    except ValueError:
        return False
