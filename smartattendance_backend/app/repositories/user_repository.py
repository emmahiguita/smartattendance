# app/repositories/user_repository.py
"""
User repository â€” abstracts all DB queries for users.
SRP: only user-related DB access.
DIP: callers depend on this interface, not on SQLAlchemy directly.
"""
from sqlalchemy.orm import Session

from app.models.user import User
from app.schemas.user import UserCreate

# Campos permitidos en update() â€” previene mass assignment de campos sensibles
# como is_active, hashed_password, o foto_url (que tiene su propio endpoint).
_ALLOWED_UPDATE_FIELDS: frozenset[str] = frozenset({
    "nombre",
    "apellido",
    "correo",
    "fecha_nacimiento",
    "telefono",
    "direccion",
    "foto_url",
})


class UserRepository:
    """Single responsibility: CRUD operations on the User table."""

    def __init__(self, db: Session) -> None:
        self._db = db

    def get_by_id(self, user_id: int) -> User | None:
        return self._db.get(User, user_id)

    def get_by_ids(self, user_ids: list[int]) -> dict[int, User]:
        """Carga usuarios en una consulta; retorna mapa por ID."""
        if not user_ids:
            return {}
        users = self._db.query(User).filter(User.id.in_(set(user_ids))).all()
        return {user.id: user for user in users}

    def get_by_cedula(self, cedula: str) -> User | None:
        return self._db.query(User).filter(User.cedula == cedula).first()

    def get_by_correo(self, correo: str) -> User | None:
        return self._db.query(User).filter(User.correo == correo).first()

    def list_all(self, skip: int = 0, limit: int = 100) -> list[User]:
        return self._db.query(User).filter(User.is_active).offset(skip).limit(limit).all()

    def create(self, data: UserCreate) -> User:
        user = User(**data.model_dump())
        self._db.add(user)
        self._db.commit()
        self._db.refresh(user)
        return user

    def update(self, user: User, data: dict) -> User:
        """Aplica solo los campos permitidos presentes en `data` y persiste.
        Filtra contra _ALLOWED_UPDATE_FIELDS para prevenir mass assignment
        de campos sensibles (is_active, hashed_password, etc.)."""
        for field, value in data.items():
            if value is not None and field in _ALLOWED_UPDATE_FIELDS:
                setattr(user, field, value)
        self._db.add(user)
        self._db.commit()
        self._db.refresh(user)
        return user

