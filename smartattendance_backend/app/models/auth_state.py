"""Estado persistente de sesiones y recuperación, sin tokens ni códigos en claro."""
from sqlalchemy import String, Float, Integer, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.database.base import Base


class AuthSession(Base):
    __tablename__ = 'auth_sessions'
    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey('users.id'), index=True)
    refresh_digest: Mapped[str] = mapped_column(String(64))
    expires_at: Mapped[float] = mapped_column(Float, index=True)
    revoked: Mapped[bool] = mapped_column(Boolean, default=False)


class PasswordChallenge(Base):
    __tablename__ = 'password_challenges'
    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    generation: Mapped[str] = mapped_column(String(36))
    digest: Mapped[str] = mapped_column(String(64))
    expires_at: Mapped[float] = mapped_column(Float, index=True)
    attempts: Mapped[int] = mapped_column(Integer, default=0)
