"""Ruta compartida para servir y escribir archivos; admite volumen persistente.

La ruta por defecto conserva el directorio público histórico del servidor.
En producción STATIC_DIRECTORY debe apuntar a un volumen o disco persistente.
"""
from pathlib import Path
from app.core.config import settings

STATIC_DIRECTORY = (
    Path(settings.STATIC_DIRECTORY).expanduser().resolve()
    if settings.STATIC_DIRECTORY
    else Path(__file__).resolve().parents[2] / 'static'
)
PROFILE_PHOTOS_DIRECTORY = STATIC_DIRECTORY / 'fotos'
