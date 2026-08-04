# app/models/user.py
"""
SQLAlchemy ORM model for the User table.
SRP: defines only the persistence schema for users.
"""
from datetime import datetime, timezone
from sqlalchemy import String, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    nombre: Mapped[str] = mapped_column(String(100))
    apellido: Mapped[str] = mapped_column(String(100))
    cedula: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    correo: Mapped[str] = mapped_column(String(150), unique=True, index=True)
    cargo: Mapped[str] = mapped_column(String(100))
    fecha_nacimiento: Mapped[str | None] = mapped_column(String(20), nullable=True)
    telefono: Mapped[str | None] = mapped_column(String(30), nullable=True)
    direccion: Mapped[str | None] = mapped_column(String(255), nullable=True)
    foto_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    # Nullable: cuentas creadas por un admin no tienen contraseña hasta que el
    # empleado la establece vía /auth/reset-password.
    hashed_password: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    attendances: Mapped[list["Attendance"]] = relationship(  # noqa: F821
        back_populates="user", cascade="all, delete-orphan"
    )

    @property
    def full_name(self) -> str:
        return f"{self.nombre} {self.apellido}"
