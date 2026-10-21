# app/api/v1/endpoints/messages.py
"""
=============================================================================
ENDPOINT: Mensajería Interna Corporativa (/api/v1/messages)
=============================================================================
QUÉ HACE:
Expone los controladores REST para intercambio de mensajes privados entre empleados.

PARA QUÉ SIRVE:
Provee endpoints para listar contactos, enviar mensajes, marcar lectura,
consultar mensajes no leídos y sincronizar lotes offline con idempotencia.

PRINCIPIOS SOLID APLICADOS:
- S (Single Responsibility): Exclusivamente enruta peticiones HTTP y delega a MessagingService.
- D (Dependency Inversion): Inyecta sesión de base de datos y usuario autenticado.
=============================================================================
"""
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.api.v1.deps import get_current_user
from app.database.base import get_db
from app.models.message import Message
from app.models.user import User
from app.schemas.message import (
    MessageContact, MessageCreate, MessageResponse,
    MessageBatchSyncRequest, MessageBatchSyncResponse
)
from app.services.messaging_service import MessagingService

router = APIRouter(prefix="/messages", tags=["Mensajería"])


@router.get("/contacts", response_model=list[MessageContact], summary="Directorio de empleados")
def contacts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[MessageContact]:
    return MessagingService(db).get_contacts(current_user)


@router.get("/", response_model=list[MessageResponse], summary="Historial de mensajes")
def list_messages(
    with_user_id: int | None = Query(None, gt=0),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=300),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[MessageResponse]:
    return MessagingService(db).list_messages(current_user, with_user_id, skip, limit)


@router.post("/", response_model=MessageResponse, status_code=status.HTTP_201_CREATED, summary="Enviar mensaje")
def send_message(
    data: MessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> MessageResponse:
    return MessagingService(db).send_message(current_user, data)


@router.patch("/read-all/{contact_id}", summary="Marcar conversación como leída")
def mark_conversation_read(
    contact_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict[str, int]:
    updated = (
        db.query(Message)
        .filter(
            Message.sender_id == contact_id,
            Message.recipient_id == current_user.id,
            Message.read_at.is_(None),
        )
        .update({Message.read_at: datetime.now(timezone.utc)}, synchronize_session=False)
    )
    db.commit()
    return {"updated": updated}


@router.patch("/{message_id}/read", response_model=MessageResponse, summary="Marcar mensaje leído")
def mark_read(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> MessageResponse:
    record = db.get(Message, message_id)
    if record is None or record.recipient_id != current_user.id:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Mensaje no encontrado.")
    if record.read_at is None:
        record.read_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(record)
    return MessagingService(db).serialize([record])[0]


@router.get("/unread/count", summary="Cantidad de mensajes no leídos")
def unread_count(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> dict[str, int]:
    count = db.query(func.count(Message.id)).filter(
        Message.recipient_id == current_user.id,
        Message.read_at.is_(None),
    ).scalar()
    return {"count": int(count or 0)}


@router.post("/sync", response_model=MessageBatchSyncResponse, status_code=200, summary="Sincronizar lote de mensajes offline")
def sync_offline_messages(
    payload: MessageBatchSyncRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> MessageBatchSyncResponse:
    return MessagingService(db).sync_offline(current_user, payload)
