# app/api/v1/endpoints/qr.py
"""
QR endpoints — generate and validate QR codes.
SRP: delegates all logic to QRService.
"""
from fastapi import APIRouter, BackgroundTasks, Depends
from sqlalchemy.orm import Session
from typing import List

from app.database.base import get_db
from app.schemas.qr import QRGenerateRequest, QRGenerateResponse, QRValidateRequest, QRValidateResponse
from app.services.qr_service import QRService
from app.repositories.qr_repository import QRRepository
from app.api.v1.deps import require_admin, get_current_user
from app.models.user import User
from pydantic import BaseModel

class QRActiveResponse(BaseModel):
    codigo: str
    usuario_id: int

router = APIRouter(prefix="/qr", tags=["Códigos QR"])

@router.get("/active", response_model=List[QRActiveResponse], summary="Obtener todos los QR activos")
def get_active_qrs(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
) -> List[QRActiveResponse]:
    """Retorna todos los códigos QR que están activos actualmente. Solo para administradores."""
    repo = QRRepository(db)
    active_qrs = repo.get_all_active()
    return [QRActiveResponse(codigo=qr.codigo, usuario_id=qr.usuario_id) for qr in active_qrs]


@router.post("/generate", response_model=QRGenerateResponse, status_code=201, summary="Generar código QR")
def generate_qr(
    request: QRGenerateRequest, 
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
) -> QRGenerateResponse:
    """
    Generate a unique QR code for an employee.
    Previous active codes for the same user are deactivated.
    Admins only.
    """
    return QRService(db).generate(request)


@router.post("/validate", response_model=QRValidateResponse, summary="Validar y registrar QR")
def validate_qr(
    request: QRValidateRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> QRValidateResponse:
    """
    Validate a QR code scanned by the mobile app.
    If valid, registers an attendance entry (with the device location when
    provided) and deactivates the code. The tipo is decided server-side.
    """
    return QRService(db).validate(request, background_tasks, current_user=current_user)
