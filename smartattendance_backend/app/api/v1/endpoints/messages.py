"""Authenticated employee-to-employee internal messaging."""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import and_, func, or_
from sqlalchemy.orm import Session

from app.api.v1.deps import get_current_user
from app.database.base import get_db
from app.models.message import Message
from app.models.user import User
from app.schemas.message import MessageContact, MessageCreate, MessageResponse

router = APIRouter(prefix="/messages", tags=["Mensajería"])


def _serialize(db: Session, records: list[Message]) -> list[MessageResponse]:
    user_ids = {value for record in records for value in (record.sender_id, record.recipient_id)}
    users = {
        user.id: user
        for user in db.query(User).filter(User.id.in_(user_ids)).all()
    } if user_ids else {}
    return [
        MessageResponse(
            id=record.id,
            sender_id=record.sender_id,
            recipient_id=record.recipient_id,
            body=record.body,
            read_at=record.read_at,
            created_at=record.created_at,
            sender_name=users[record.sender_id].full_name,
            recipient_name=users[record.recipient_id].full_name,
        )
        for record in records
    ]


@router.get("/contacts", response_model=list[MessageContact], summary="Directorio de empleados")
def contacts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[MessageContact]:
    users = (
        db.query(User)
        .filter(User.is_active, User.id != current_user.id)
        .order_by(User.nombre, User.apellido)
        .all()
    )
    unread_rows = (
        db.query(Message.sender_id, func.count(Message.id))
        .filter(Message.recipient_id == current_user.id, Message.read_at.is_(None))
        .group_by(Message.sender_id)
        .all()
    )
    unread = dict(unread_rows)
    recent = (
        db.query(Message)
        .filter(or_(
            Message.sender_id == current_user.id,
            Message.recipient_id == current_user.id,
        ))
        .order_by(Message.created_at.desc())
        .all()
    )
    latest_by_contact: dict[int, Message] = {}
    for message in recent:
        contact_id = (
            message.recipient_id
            if message.sender_id == current_user.id
            else message.sender_id
        )
        latest_by_contact.setdefault(contact_id, message)

    result = []
    for user in users:
        last = latest_by_contact.get(user.id)
        result.append(MessageContact(
            id=user.id,
            nombre=user.nombre,
            apellido=user.apellido,
            cargo=user.cargo,
            foto_url=user.foto_url,
            unread_count=unread.get(user.id, 0),
            last_message=last.body if last else None,
            last_message_at=last.created_at if last else None,
        ))
    result.sort(key=lambda item: item.last_message_at.timestamp() if item.last_message_at else 0.0, reverse=True)
    return result


@router.get("/", response_model=list[MessageResponse], summary="Historial de mensajes")
def list_messages(
    with_user_id: int | None = Query(None, gt=0),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=300),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[MessageResponse]:
    query = db.query(Message).filter(or_(
        Message.sender_id == current_user.id,
        Message.recipient_id == current_user.id,
    ))
    if with_user_id is not None:
        query = query.filter(or_(
            and_(Message.sender_id == current_user.id, Message.recipient_id == with_user_id),
            and_(Message.sender_id == with_user_id, Message.recipient_id == current_user.id),
        ))
    records = query.order_by(Message.created_at.desc()).offset(skip).limit(limit).all()
    records.reverse()
    return _serialize(db, records)


@router.post("/", response_model=MessageResponse, status_code=status.HTTP_201_CREATED, summary="Enviar mensaje")
def send_message(
    data: MessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> MessageResponse:
    if data.recipient_id == current_user.id:
        raise HTTPException(status_code=400, detail="No puedes enviarte mensajes a ti mismo.")
    recipient = db.get(User, data.recipient_id)
    if recipient is None or not recipient.is_active:
        raise HTTPException(status_code=404, detail="Empleado destinatario no encontrado o inactivo.")
    record = Message(sender_id=current_user.id, recipient_id=recipient.id, body=data.body)
    db.add(record)
    db.commit()
    db.refresh(record)
    return _serialize(db, [record])[0]


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
        .update(
            {Message.read_at: datetime.now(timezone.utc)},
            synchronize_session=False,
        )
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
        raise HTTPException(status_code=404, detail="Mensaje no encontrado.")
    if record.read_at is None:
        record.read_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(record)
    return _serialize(db, [record])[0]


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


