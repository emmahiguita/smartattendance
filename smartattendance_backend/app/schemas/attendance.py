# app/schemas/attendance.py
"""
Pydantic schemas for Attendance records.
ISP: separate schemas for creation and response.
"""
from datetime import date, time, datetime
from typing import Literal
from pydantic import BaseModel


AttendanceType = Literal[
    "entrada",
    "salida_almuerzo",
    "regreso_almuerzo",
    "salida",
]


class AttendanceCreate(BaseModel):
    usuario_id: int
    # None → el servidor decide el tipo automáticamente según la jornada
    # (entrada → salida_almuerzo → regreso_almuerzo → salida).
    # El cliente jamás decide el tipo: evita manipular el reloj del dispositivo.
    tipo: AttendanceType | None = None
    latitud: float | None = None
    longitud: float | None = None
    direccion: str | None = None
    uuid_marca: str | None = None


class AttendanceResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: int
    usuario_id: int
    fecha: date
    hora: time
    tipo: str
    latitud: float | None = None
    longitud: float | None = None
    direccion: str | None = None
    uuid_marca: str | None = None
    created_at: datetime


class AttendanceWithUser(AttendanceResponse):
    """Extended response that includes denormalized user data."""
    nombre: str = ""
    apellido: str = ""
    cedula: str = ""
