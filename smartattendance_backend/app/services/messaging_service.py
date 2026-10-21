# app/services/messaging_service.py
"""
=============================================================================
SERVICIO: MessagingService
=============================================================================
QUÉ HACE:
Gestiona la mensajería interna privada y segura entre colaboradores de la empresa.

PARA QUÉ SIRVE:
Permite la comunicación en tiempo real entre cuadrillas móviles en campo y personal
administrativo en planta fija, incluyendo sincronización de mensajes fuera de línea.

PRINCIPIOS SOLID APLICADOS:
- S (Single Responsibility): Exclusivamente responsable de la lógica de mensajería.
- D (Dependency Inversion): Inyecta la sesión de base de datos SQLAlchemy.
=============================================================================
"""
from datetime import datetime, timezone
from sqlalchemy import and_, func, or_
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.message import Message
from app.models.user import User
from app.schemas.message import (
    MessageContact, MessageCreate, MessageResponse,
    MessageBatchSyncRequest, MessageBatchSyncResponse
)


class MessagingService:
    """Servicio de mensajería interna corporativa."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def serialize(self, records: list[Message]) -> list[MessageResponse]:
        """Serializa modelos Message a DTOs MessageResponse enriquecidos con nombres."""
        user_ids = {val for r in records for val in (r.sender_id, r.recipient_id)}
        users = {u.id: u for u in self.db.query(User).filter(User.id.in_(user_ids)).all()} if user_ids else {}

        return [
            MessageResponse(
                id=r.id,
                sender_id=r.sender_id,
                recipient_id=r.recipient_id,
                body=r.body,
                read_at=r.read_at,
                created_at=r.created_at,
                sender_name=users[r.sender_id].full_name if r.sender_id in users else "Usuario no disponible",
                recipient_name=users[r.recipient_id].full_name if r.recipient_id in users else "Usuario no disponible",
            )
            for r in records
        ]

    def get_contacts(self, current_user: User) -> list[MessageContact]:
        """Obtiene el directorio de empleados activos con conteo de no leídos y último mensaje."""
        users = (
            self.db.query(User)
            .filter(User.is_active, User.id != current_user.id)
            .order_by(User.nombre, User.apellido)
            .all()
        )
        unread_rows = (
            self.db.query(Message.sender_id, func.count(Message.id))
            .filter(Message.recipient_id == current_user.id, Message.read_at.is_(None))
            .group_by(Message.sender_id)
            .all()
        )
        unread = dict(unread_rows)
        recent = (
            self.db.query(Message)
            .filter(or_(Message.sender_id == current_user.id, Message.recipient_id == current_user.id))
            .order_by(Message.created_at.desc())
            .all()
        )
        latest_by_contact: dict[int, Message] = {}
        for m in recent:
            cid = m.recipient_id if m.sender_id == current_user.id else m.sender_id
            latest_by_contact.setdefault(cid, m)

        result = [
            MessageContact(
                id=u.id, nombre=u.nombre, apellido=u.apellido, cargo=u.cargo,
                foto_url=u.foto_url, unread_count=unread.get(u.id, 0),
                last_message=latest_by_contact.get(u.id).body if latest_by_contact.get(u.id) else None,
                last_message_at=latest_by_contact.get(u.id).created_at if latest_by_contact.get(u.id) else None,
            )
            for u in users
        ]
        result.sort(key=lambda x: x.last_message_at.timestamp() if x.last_message_at else 0.0, reverse=True)
        return result

    def list_messages(self, current_user: User, with_user_id: int | None, skip: int, limit: int) -> list[MessageResponse]:
        """Lista la conversación privada entre el usuario actual y otro empleado."""
        query = self.db.query(Message).filter(or_(
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
        return self.serialize(records)

    def send_message(self, current_user: User, data: MessageCreate) -> MessageResponse:
        """Valida y envía un mensaje privado."""
        if data.recipient_id == current_user.id:
            raise HTTPException(status_code=400, detail="No puedes enviarte mensajes a ti mismo.")
        recipient = self.db.get(User, data.recipient_id)
        if recipient is None or not recipient.is_active:
            raise HTTPException(status_code=404, detail="Empleado destinatario no encontrado o inactivo.")
        record = Message(sender_id=current_user.id, recipient_id=recipient.id, body=data.body)
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)
        return self.serialize([record])[0]

    def sync_offline(self, current_user: User, payload: MessageBatchSyncRequest) -> MessageBatchSyncResponse:
        """Sincroniza en lote mensajes generados sin conexión a internet."""
        procesados = 0
        errores = 0
        detalles = []
        seen_ids: set[int] = set()

        for item in payload.messages:
            cid = item.client_id
            if cid in seen_ids:
                detalles.append({"client_id": cid, "status": "duplicado_ignorado"})
                continue
            seen_ids.add(cid)

            try:
                if item.recipient_id == current_user.id:
                    errores += 1
                    detalles.append({"client_id": cid, "status": "error_self_message"})
                    continue

                recipient = self.db.get(User, item.recipient_id)
                if (recipient is None or not recipient.is_active) and item.recipient_cedula:
                    recipient = self.db.query(User).filter(User.cedula == item.recipient_cedula, User.is_active == True).first()

                if recipient is None or not recipient.is_active:
                    errores += 1
                    detalles.append({"client_id": cid, "status": "error_recipient_inactive"})
                    continue

                created = datetime.now(timezone.utc)
                if item.created_at:
                    try:
                        created = datetime.fromisoformat(item.created_at)
                    except ValueError:
                        pass

                record = Message(sender_id=current_user.id, recipient_id=recipient.id, body=item.body, created_at=created)
                self.db.add(record)
                self.db.commit()
                self.db.refresh(record)
                procesados += 1
                detalles.append({"client_id": cid, "status": "creado", "server_id": record.id})
            except Exception as e:
                self.db.rollback()
                errores += 1
                detalles.append({"client_id": cid, "status": "error", "mensaje": str(e)})

        return MessageBatchSyncResponse(procesados=procesados, errores=errores, detalles=detalles)
