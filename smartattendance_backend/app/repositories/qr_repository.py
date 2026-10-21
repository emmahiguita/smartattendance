# app/repositories/qr_repository.py
"""
QR code repository — abstracts all DB queries for QR codes.
SRP: only QR-related DB access.
"""
from sqlalchemy.orm import Session

from app.models.qr_code import QRCode


class QRRepository:
    """Single responsibility: CRUD operations on the QRCode table."""

    def __init__(self, db: Session) -> None:
        self._db = db

    def get_by_codigo(self, codigo: str) -> QRCode | None:
        return self._db.query(QRCode).filter(QRCode.codigo == codigo).first()

    def get_active_by_user(self, user_id: int) -> QRCode | None:
        return (
            self._db.query(QRCode)
            .filter(QRCode.usuario_id == user_id, QRCode.estado.is_(True))
            .first()
        )

    def get_all_active(self) -> list[QRCode]:
        return self._db.query(QRCode).filter(QRCode.estado.is_(True)).all()

    def create(self, codigo: str, user_id: int) -> QRCode:
        qr = QRCode(codigo=codigo, usuario_id=user_id)
        self._db.add(qr)
        self._db.commit()
        self._db.refresh(qr)
        return qr

    def deactivate(self, qr: QRCode) -> QRCode:
        qr.estado = False
        self._db.commit()
        self._db.refresh(qr)
        return qr
