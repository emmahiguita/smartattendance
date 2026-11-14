"""Password reset OTP delivery and verification."""
from email.message import EmailMessage
import smtplib
import ssl

from fastapi import HTTPException, status

from app.core.config import settings
from app.services import challenge_store


class PasswordResetService:
    def request_code(self, cedula: str, correo: str, db) -> None:
        if not all((settings.SMTP_HOST, settings.SMTP_USERNAME, settings.SMTP_PASSWORD, settings.SMTP_FROM)):
            raise HTTPException(status_code=503, detail="El correo de recuperación no está configurado.")
        code, generation = challenge_store.issue(db, cedula, correo)
        message = EmailMessage()
        message["Subject"] = "Código de recuperación - SmartAttendance"
        message["From"] = settings.SMTP_FROM
        message["To"] = correo
        message.set_content(f"Tu código de recuperación es: {code}\n\nVence en 10 minutos. No lo compartas.")
        try:
            with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT, timeout=20) as server:
                server.starttls(context=ssl.create_default_context())
                server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
                server.send_message(message)
        except OSError as exc:
            challenge_store.discard(db, cedula, correo, generation)
            raise HTTPException(status_code=502, detail="No se pudo enviar el código de recuperación.") from exc

    def verify_code(self, cedula: str, correo: str, code: str, db) -> None:
        challenge_store.consume(db, cedula, correo, code)


password_reset_service = PasswordResetService()
