# app/schemas/qr.py
"""
Pydantic schemas for QR code operations.
ISP: separate schemas per operation type.
"""
from datetime import datetime
from pydantic import BaseModel


class QRGenerateRequest(BaseModel):
    usuario_id: int


class QRGenerateResponse(BaseModel):
    codigo: str
    usuario_id: int
    fecha_generacion: datetime
    estado: bool


class QRValidateRequest(BaseModel):
    codigo: str
    # Ubicación capturada por el dispositivo al momento del escaneo (opcional).
    latitud: float | None = None
    longitud: float | None = None
    direccion: str | None = None


class QRValidateResponse(BaseModel):
    valid: bool
    usuario_id: int | None = None
    mensaje: str
    # Datos del registro creado (cuando valid=True) — el servidor decide todo.
    tipo: str | None = None
    fecha_registro: str | None = None  # YYYY-MM-DD
    hora_registro: str | None = None   # HH:MM:SS
