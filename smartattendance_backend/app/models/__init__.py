# Importar todos los modelos para que SQLAlchemy los registre en Base.metadata
# antes de que create_all_tables() sea llamado en cualquier contexto.
from app.models.user import User
from app.models.attendance import Attendance
from app.models.qr_code import QRCode
from app.models.message import Message

__all__ = ["User", "Attendance", "QRCode", "Message"]


