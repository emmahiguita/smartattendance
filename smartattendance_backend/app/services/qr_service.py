# app/services/qr_service.py
"""
QR service — business logic for generating and validating QR codes.
SRP: handles only QR use cases.
OCP: new QR strategies (e.g., time-limited) can be added without modifying this class.
"""
import re
import uuid
from sqlalchemy.orm import Session

from app.repositories.qr_repository import QRRepository
from app.repositories.user_repository import UserRepository
from app.schemas.qr import QRGenerateRequest, QRGenerateResponse, QRValidateRequest, QRValidateResponse
from app.schemas.attendance import AttendanceCreate
from app.services.attendance_service import AttendanceService
from app.api.v1.deps import is_admin
from fastapi import BackgroundTasks, HTTPException, status


class QRService:
    """Generates unique QR codes and validates them to register attendance."""

    def __init__(self, db: Session) -> None:
        self._db = db
        self._qr_code_repo = QRRepository(db)
        self._user_repo = UserRepository(db)

    def generate(self, request: QRGenerateRequest) -> QRGenerateResponse:
        """Generate a new active QR code for the given user, deactivating any previous."""
        user = self._user_repo.get_by_id(request.usuario_id)
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Usuario no encontrado.",
            )

        # Deactivate previous active code (OCP: policy isolated here)
        existing = self._qr_code_repo.get_active_by_user(request.usuario_id)
        if existing:
            self._qr_code_repo.deactivate(existing)

        codigo = str(uuid.uuid4())
        qr = self._qr_code_repo.create(codigo=codigo, user_id=request.usuario_id)

        return QRGenerateResponse(
            codigo=qr.codigo,
            usuario_id=qr.usuario_id,
            fecha_generacion=qr.fecha_generacion,
            estado=qr.estado,
        )

    def validate(
        self,
        request: QRValidateRequest,
        background_tasks: BackgroundTasks,
        current_user=None,
    ) -> QRValidateResponse:
        """
        Validate a QR code and register an attendance entry if valid.

        Supports raw UUIDs as well as corporate prefix formats for Empresa X 
        (e.g. 'EMPRESA_X:uuid' or 'EMPRESA_X_uuid').

        The attendance `tipo` is decided SERVER-SIDE (entrada/salida by workday
        state) — the client clock is never trusted. The QR code is single-use.
        """
        raw_code = request.codigo.strip()
        # Normalización de formato corporativo de Empresa X
        # Extrae el UUID si viene con prefijos como EMPRESA_X:uuid o EMPRESA_X_uuid
        uuid_match = re.search(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', raw_code, re.IGNORECASE)
        if uuid_match:
            clean_code = uuid_match.group(0)
        elif ":" in raw_code:
            clean_code = raw_code.split(":", 1)[1].strip()
        elif raw_code.upper().startswith("EMPRESA"):
            clean_code = re.sub(r'^EMPRESA[A-Z0-9_]*[:_]', '', raw_code, flags=re.IGNORECASE).strip()
        else:
            clean_code = raw_code

        qr = self._qr_code_repo.get_by_codigo(clean_code)
        if qr is None:
            # Intentar búsqueda con el código raw si no se encontró con clean_code
            qr = self._qr_code_repo.get_by_codigo(raw_code)

        if qr is None or not qr.estado:
            return QRValidateResponse(
                valid=False,
                mensaje="Código QR inválido, expirado o no pertenece a Empresa X.",
            )

        # Ownership: a non-admin can only consume their own QR code.
        if current_user is not None and not is_admin(current_user) and qr.usuario_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Este código QR pertenece a otro empleado.",
            )

        # Register attendance entry via QR — tipo auto-decided server-side,
        # reusing the same workday logic as the manual flow. La ubicación del
        # escaneo (si el dispositivo la envió) queda en el registro.
        record = AttendanceService(self._db).register(
            AttendanceCreate(
                usuario_id=qr.usuario_id,
                tipo=None,
                latitud=request.latitud,
                longitud=request.longitud,
                direccion=request.direccion,
            ),
            background_tasks,
        )

        # Deactivate QR after use (single-use policy)
        self._qr_code_repo.deactivate(qr)

        return QRValidateResponse(
            valid=True,
            usuario_id=qr.usuario_id,
            mensaje="Asistencia registrada correctamente.",
            tipo=record.tipo,
            fecha_registro=record.fecha.isoformat() if record.fecha else None,
            hora_registro=record.hora.strftime("%H:%M:%S") if record.hora else None,
        )
