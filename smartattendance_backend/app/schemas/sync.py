# app/schemas/sync.py
"""
Pydantic schemas for Offline Batch Sync.
"""
from datetime import datetime
from typing import Literal
from pydantic import BaseModel, Field

AttendanceType = Literal[
    "entrada",
    "salida_almuerzo",
    "regreso_almuerzo",
    "salida",
]

class AttendanceOfflineItem(BaseModel):
    uuid_marca: str = Field(..., description="UUID único generado por la app localmente para idempotencia")
    usuario_id: int
    fecha_hora_local: datetime = Field(..., description="Timestamp capturado localmente en el dispositivo")
    tipo: AttendanceType | None = None
    latitud: float | None = None
    longitud: float | None = None
    direccion: str | None = None
    foto_base64: str | None = Field(None, description="Foto en Base64 tomada como evidencia biométrica")
    foto_url: str | None = Field(None, description="URL pública de la foto si ya fue cargada")

class AttendanceBatchSyncRequest(BaseModel):
    records: list[AttendanceOfflineItem]

class AttendanceBatchSyncResponse(BaseModel):
    procesados: int
    ignorados_duplicados: int
    errores: int
    detalles: list[dict]
