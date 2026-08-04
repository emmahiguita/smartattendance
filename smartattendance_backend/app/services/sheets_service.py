import io
import logging
import os
from datetime import date, datetime, time
from typing import Dict, List, Tuple

from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill
from sqlalchemy.orm import Session

from app.database.base import SessionLocal
from app.models.attendance import Attendance
from app.models.user import User

logger = logging.getLogger(__name__)

COLOR_PRESENTE   = "10B981"
COLOR_ALMUERZO   = "F59E0B"
COLOR_FINALIZADO = "2563EB"
COLOR_AUSENTE    = "EF4444"


class SheetsService:
    def __init__(self, db: Session):
        self.db = db

    @staticmethod
    def _as_datetime(t: time) -> datetime:
        """datetime.time no es restable; se combina con una fecha arbitraria."""
        return datetime.combine(date(2000, 1, 1), t)

    def generate_excel_bytes(self, records: List[Attendance]) -> bytes:
        """Genera Excel en memoria con los registros de asistencia. Retorna bytes .xlsx."""
        wb = Workbook()
        ws = wb.active
        ws.title = "ASISTENCIAS"

        headers = [
            "Nombre", "Cedula", "Cargo", "Fecha",
            "Entrada", "Salida Almuerzo", "Regreso Almuerzo", "Salida Final", "Horas Laboradas", "Estado",
        ]
        ws.append(headers)

        header_font = Font(bold=True, color="FFFFFF")
        header_fill = PatternFill(start_color="374151", end_color="374151", fill_type="solid")
        for col in range(1, len(headers) + 1):
            cell = ws.cell(row=1, column=col)
            cell.font = header_font
            cell.fill = header_fill
            cell.alignment = Alignment(horizontal="center")

        # Agrupar por (usuario_id, fecha) y ordenar por hora dentro de cada grupo
        grouped: Dict[Tuple[int, date], List[Attendance]] = {}
        for record in records:
            key = (record.usuario_id, record.fecha)
            grouped.setdefault(key, []).append(record)

        for key in grouped:
            grouped[key].sort(key=lambda r: r.hora)

        user_ids = {user_id for user_id, _ in grouped}
        users_by_id = {
            user.id: user
            for user in self.db.query(User).filter(User.id.in_(user_ids)).all()
        } if user_ids else {}

        row_idx = 2
        # Ordenar por fecha desc, luego por user_id asc para salida consistente
        for (user_id, record_date) in sorted(grouped.keys(), key=lambda k: (k[1], k[0]), reverse=False):
            user_records = grouped[(user_id, record_date)]
            user = users_by_id.get(user_id)
            if not user:
                continue

            fecha_str = record_date.strftime("%d/%m/%Y")
            entrada = salida_almuerzo = regreso_almuerzo = salida_final = "-"
            estado, estado_color = "Ausente", COLOR_AUSENTE

            # Mapear por tipo
            times_by_type = {r.tipo: r.hora for r in user_records}
            if "entrada" in times_by_type:
                entrada = times_by_type["entrada"].strftime("%H:%M")
                estado, estado_color = "Trabajando", COLOR_PRESENTE
            if "salida_almuerzo" in times_by_type:
                salida_almuerzo = times_by_type["salida_almuerzo"].strftime("%H:%M")
                estado, estado_color = "Almuerzo", COLOR_ALMUERZO
            if "regreso_almuerzo" in times_by_type:
                regreso_almuerzo = times_by_type["regreso_almuerzo"].strftime("%H:%M")
                estado, estado_color = "Trabajando", COLOR_PRESENTE
            if "salida" in times_by_type:
                salida_final = times_by_type["salida"].strftime("%H:%M")
                estado, estado_color = "Finalizado", COLOR_FINALIZADO

            # Cálculo de horas laboradas
            # Bug fix: datetime.time no es restable â†’ convertir a datetime.
            total_seconds = 0
            if "entrada" in times_by_type and "salida_almuerzo" in times_by_type:
                d1 = (self._as_datetime(times_by_type["salida_almuerzo"])
                      - self._as_datetime(times_by_type["entrada"])).total_seconds()
                if d1 > 0:
                    total_seconds += d1
            elif "entrada" in times_by_type and "salida" in times_by_type and "salida_almuerzo" not in times_by_type:
                d1 = (self._as_datetime(times_by_type["salida"])
                      - self._as_datetime(times_by_type["entrada"])).total_seconds()
                if d1 > 0:
                    total_seconds += d1

            if "regreso_almuerzo" in times_by_type and "salida" in times_by_type:
                d2 = (self._as_datetime(times_by_type["salida"])
                      - self._as_datetime(times_by_type["regreso_almuerzo"])).total_seconds()
                if d2 > 0:
                    total_seconds += d2

            if total_seconds > 0:
                h = int(total_seconds // 3600)
                m = int((total_seconds % 3600) // 60)
                horas_laboradas = f"{h}h {m:02d}m"
            else:
                horas_laboradas = "-"

            row_data = [
                f"{user.nombre} {user.apellido}", user.cedula, user.cargo, fecha_str,
                entrada, salida_almuerzo, regreso_almuerzo, salida_final, horas_laboradas, estado,
            ]
            for col_idx, value in enumerate(row_data, start=1):
                cell = ws.cell(row=row_idx, column=col_idx, value=value)
                cell.alignment = Alignment(horizontal="center")
                if col_idx == 10:
                    cell.font = Font(color="FFFFFF", bold=True)
                    cell.fill = PatternFill(
                        start_color=estado_color, end_color=estado_color, fill_type="solid"
                    )
            row_idx += 1

        for col in range(1, len(headers) + 1):
            ws.column_dimensions[ws.cell(row=1, column=col).column_letter].width = 20

        output = io.BytesIO()
        wb.save(output)
        output.seek(0)
        return output.read()

    def sync_to_google_sheets(self, attendance_id: int) -> None:
        """Sincroniza un registro con Google Sheets en segundo plano.

        Usa su PROPIA sesión de DB (no la de la request HTTP) porque este método
        se ejecuta en un BackgroundTask donde la sesión original puede estar cerrada.

        Requiere google_credentials.json o credentials.json en el directorio de trabajo.
        Sin credenciales, registra warning y sale â€” nunca bloquea la respuesta HTTP.
        """
        db = SessionLocal()
        try:
            attendance = db.query(Attendance).filter(Attendance.id == attendance_id).first()
            if attendance is None:
                logger.warning("[GoogleSheets] Registro #%s no encontrado en la DB.", attendance_id)
                return

            creds_file = next(
                (f for f in ("google_credentials.json", "credentials.json") if os.path.exists(f)),
                None,
            )

            if not creds_file:
                user = db.query(User).filter(User.id == attendance.usuario_id).first()
                user_name = f"{user.nombre} {user.apellido}" if user else f"ID {attendance.usuario_id}"
                logger.warning(
                    "[GoogleSheets] Credenciales no encontradas. "
                    "Marca registrada solo localmente: %s (%s)",
                    user_name,
                    attendance.tipo,
                )
                return

            try:
                import gspread
                from google.oauth2.service_account import Credentials

                scopes = [
                    "https://www.googleapis.com/auth/spreadsheets",
                    "https://www.googleapis.com/auth/drive",
                ]
                creds  = Credentials.from_service_account_file(creds_file, scopes=scopes)
                client = gspread.authorize(creds)

                sheet_name = os.getenv("GOOGLE_SHEET_NAME", "Asistencias_SmartAttendance")
                try:
                    sheet = client.open(sheet_name).sheet1
                except Exception:
                    spreadsheet = client.create(sheet_name)
                    sheet = spreadsheet.sheet1
                    sheet.append_row(
                        ["ID Usuario", "Nombre", "Cédula", "Tipo de Marca", "Fecha", "Hora"]
                    )

                user = db.query(User).filter(User.id == attendance.usuario_id).first()
                user_nombre = f"{user.nombre} {user.apellido}" if user else "Desconocido"
                user_cedula = user.cedula if user else "---"

                sheet.append_row([
                    attendance.usuario_id,
                    user_nombre,
                    user_cedula,
                    attendance.tipo.upper(),
                    attendance.fecha.strftime("%d/%m/%Y"),
                    attendance.hora.strftime("%H:%M:%S"),
                ])
                logger.info(
                    "[GoogleSheets] Registro sincronizado en '%s': %s - %s",
                    sheet_name,
                    user_nombre,
                    attendance.tipo,
                )
            except Exception:
                logger.exception("[GoogleSheets] Error al sincronizar con Google Sheets. "
                                 "El registro #%s queda SOLO en la DB local.", attendance_id)
        finally:
            db.close()


