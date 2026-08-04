# app/models/qr_code.py
"""
SQLAlchemy ORM model for generated QR codes.
SRP: defines only the persistence schema for QR codes.
"""
from datetime import datetime, timezone
from sqlalchemy import String, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column

from app.database.base import Base


class QRCode(Base):
    __tablename__ = "qr_codes"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    codigo: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    usuario_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    fecha_generacion: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
    estado: Mapped[bool] = mapped_column(Boolean, default=True)  # True = active
