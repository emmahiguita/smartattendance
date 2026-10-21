# app/models/attendance.py
"""
SQLAlchemy ORM model for the Attendance table.
SRP: defines only the persistence schema for attendance records.
"""
from datetime import datetime, timezone, date, time
from typing import Literal
from sqlalchemy import String, DateTime, Date, Time, ForeignKey, Enum as SAEnum, Float
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.base import Base

AttendanceType = Literal[
    "entrada",
    "salida_almuerzo",
    "regreso_almuerzo",
    "salida",
    "hora_extra_entrada",
    "hora_extra_salida",
]


class Attendance(Base):
    __tablename__ = "attendance"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    usuario_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    fecha: Mapped[date] = mapped_column(Date, index=True)
    hora: Mapped[time] = mapped_column(Time)
    tipo: Mapped[str] = mapped_column(
        SAEnum(
            "entrada",
            "salida_almuerzo",
            "regreso_almuerzo",
            "salida",
            "hora_extra_entrada",
            "hora_extra_salida",
            name="attendance_type",
        ),
        nullable=False,
    )
    latitud: Mapped[float] = mapped_column(Float, nullable=True)
    longitud: Mapped[float] = mapped_column(Float, nullable=True)
    direccion: Mapped[str] = mapped_column(String, nullable=True)
    uuid_marca: Mapped[str | None] = mapped_column(String, nullable=True, unique=True, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    user: Mapped["User"] = relationship(back_populates="attendances")  # noqa: F821

