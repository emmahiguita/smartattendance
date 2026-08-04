"""Password reset OTP delivery and verification."""
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage
import secrets
import smtplib
import ssl

from fastapi import HTTPException, status

from app.core.config import settings


class PasswordResetService:
    _challenges: dict[str, tuple[str, datetime, int]] = {}

    @staticmethod
    def _key(cedula: str, correo: str) -> str:
        return f"{cedula.strip()}:{correo.strip().lower()}"

    def request_code(self, cedula: str, correo: str) -> None:
        if not all((settings.SMTP_HOST, settings.SMTP_USERNAME, settings.SMTP_PASSWORD, settings.SMTP_FROM)):
            raise HTTPException(status_code=503, detail="El correo de recuperación no está configurado.")
        code = f"{secrets.randbelow(1_000_000):06d}"
        key = self._key(cedula, correo)
        self._challenges[key] = (code, datetime.now(timezone.utc) + timedelta(minutes=10), 0)
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
            self._challenges.pop(key, None)
            raise HTTPException(status_code=502, detail="No se pudo enviar el código de recuperación.") from exc

    def verify_code(self, cedula: str, correo: str, code: str) -> None:
        key = self._key(cedula, correo)
        challenge = self._challenges.get(key)
        if challenge is None:
            raise HTTPException(status_code=400, detail="Solicita un código de recuperación primero.")
        expected, expires_at, attempts = challenge
        if datetime.now(timezone.utc) >= expires_at or attempts >= 5:
            self._challenges.pop(key, None)
            raise HTTPException(status_code=400, detail="El código expiró o superó los intentos permitidos.")
        if not secrets.compare_digest(expected, code.strip()):
            self._challenges[key] = (expected, expires_at, attempts + 1)
            raise HTTPException(status_code=400, detail="Código de verificación inválido.")
        self._challenges.pop(key, None)


password_reset_service = PasswordResetService()
