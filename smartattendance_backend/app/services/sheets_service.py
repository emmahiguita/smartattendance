import io
import logging
import os
from datetime import date, datetime, time
from typing import Dict, List, Tuple

from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill, Border, Side
from openpyxl.utils import get_column_letter
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

    def generate_excel_bytes(
        self,
        records: List[Attendance],
        fecha_desde: date | None = None,
        fecha_hasta: date | None = None,
    ) -> bytes:
        """Genera Excel profesional en memoria con formato corporativo completo."""
        wb = Workbook()
        ws = wb.active
        ws.title = "ASISTENCIAS"

        # ── Estilos reutilizables ──
        thin_side = Side(style="thin", color="D1D5DB")
        data_border = Border(
            left=thin_side, right=thin_side, top=thin_side, bottom=thin_side,
        )
        header_font = Font(bold=True, color="FFFFFF", size=11)
        header_fill = PatternFill(start_color="374151", end_color="374151", fill_type="solid")
        header_align = Alignment(horizontal="center", vertical="center", wrap_text=True)
        data_align = Alignment(horizontal="center", vertical="center")
        zebra_fill = PatternFill(start_color="F9FAFB", end_color="F9FAFB", fill_type="solid")
        white_fill = PatternFill(start_color="FFFFFF", end_color="FFFFFF", fill_type="solid")
        title_font = Font(bold=True, color="1F2937", size=14)
        subtitle_font = Font(color="6B7280", size=10)
        footer_font = Font(color="9CA3AF", size=9, italic=True)

        headers = [
            "Nombre", "Cédula", "Cargo", "Fecha",
            "Entrada", "Salida Almuerzo", "Regreso Almuerzo", "Salida Final",
            "Horas Laboradas", "Estado",
        ]

        # ── Título ──
        ws.merge_cells(start_row=1, start_column=1, end_row=1, end_column=len(headers))
        rango_str = ""
        if fecha_desde and fecha_hasta:
            rango_str = f" — {fecha_desde.strftime('%d/%m/%Y')} al {fecha_hasta.strftime('%d/%m/%Y')}"
        elif fecha_desde:
            rango_str = f" — desde {fecha_desde.strftime('%d/%m/%Y')}"
        elif fecha_hasta:
            rango_str = f" — hasta {fecha_hasta.strftime('%d/%m/%Y')}"
        title_cell = ws.cell(row=1, column=1, value=f"SmartAttendance · Reporte de Asistencias{rango_str}")
        title_cell.font = title_font
        title_cell.alignment = Alignment(horizontal="left", vertical="center")
        ws.row_dimensions[1].height = 32

        # ── Subtítulo (cantidad de registros) ──
        ws.merge_cells(start_row=2, start_column=1, end_row=2, end_column=len(headers))
        sub_cell = ws.cell(row=2, column=1,
                           value=f"{len(records)} registros · {len({r.usuario_id for r in records})} empleados · generado el {datetime.now().strftime('%d/%m/%Y %H:%M')}")
        sub_cell.font = subtitle_font
        sub_cell.alignment = Alignment(horizontal="left", vertical="center")
        ws.row_dimensions[2].height = 22

        # ── Header row (fila 3) ──
        for col_idx, header in enumerate(headers, start=1):
            cell = ws.cell(row=3, column=col_idx, value=header)
            cell.font = header_font
            cell.fill = header_fill
            cell.alignment = header_align
            cell.border = data_border
        ws.row_dimensions[3].height = 28

        # ── Agrupar datos ──
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

        # ── Escribir datos ──
        row_idx = 4
        for (user_id, record_date) in sorted(grouped.keys(), key=lambda k: (k[1], k[0])):
            user_records = grouped[(user_id, record_date)]
            user = users_by_id.get(user_id)
            if not user:
                continue

            fecha_str = record_date.strftime("%d/%m/%Y")
            entrada = salida_almuerzo = regreso_almuerzo = salida_final = "-"
            estado, estado_color = "Ausente", COLOR_AUSENTE

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

            # Horas laboradas
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

            # Horas extras calculadas
            if "hora_extra_entrada" in times_by_type and "hora_extra_salida" in times_by_type:
                d_extra = (self._as_datetime(times_by_type["hora_extra_salida"])
                           - self._as_datetime(times_by_type["hora_extra_entrada"])).total_seconds()
                if d_extra > 0:
                    total_seconds += d_extra

            horas_laboradas = f"{int(total_seconds // 3600)}h {int((total_seconds % 3600) // 60):02d}m" if total_seconds > 0 else "-"

            row_data = [
                f"{user.nombre} {user.apellido}", user.cedula, user.cargo, fecha_str,
                entrada, salida_almuerzo, regreso_almuerzo, salida_final, horas_laboradas, estado,
            ]

            # Zebra striping
            row_fill = zebra_fill if (row_idx % 2 == 0) else white_fill

            for col_idx, value in enumerate(row_data, start=1):
                cell = ws.cell(row=row_idx, column=col_idx, value=value)
                cell.alignment = data_align
                cell.border = data_border
                cell.fill = row_fill

                if col_idx == 10:  # Estado
                    cell.font = Font(color="FFFFFF", bold=True, size=11)
                    cell.fill = PatternFill(
                        start_color=estado_color, end_color=estado_color, fill_type="solid",
                    )

            # Ancho condicional: nombre y cargo más espacio en pantallas
            nombre_len = len(f"{user.nombre} {user.apellido}")
            ws.row_dimensions[row_idx].height = 22 if nombre_len < 30 else 28

            row_idx += 1

        # ── Auto-ancho de columnas adaptativo ──
        col_widths = {
            1: 28, 2: 16, 3: 22, 4: 14,       # Nombre, Cédula, Cargo, Fecha
            5: 12, 6: 18, 7: 18, 8: 16,       # Horarios
            9: 18, 10: 16,                      # Horas, Estado
        }
        for col_num, width in col_widths.items():
            ws.column_dimensions[get_column_letter(col_num)].width = width

        # ── Freeze panes: título + subtítulo + header siempre visibles ──
        ws.freeze_panes = "A4"

        # ── Auto-filtro en todas las columnas ──
        last_col_letter = get_column_letter(len(headers))
        ws.auto_filter.ref = f"A3:{last_col_letter}{row_idx - 1}"

        # ── Footer ──
        footer_row = row_idx + 2
        ws.merge_cells(start_row=footer_row, start_column=1, end_row=footer_row, end_column=len(headers))
        footer_cell = ws.cell(row=footer_row, column=1,
                              value=f"SmartAttendance © {datetime.now().year} — Generado automáticamente. Solo para uso interno.")
        footer_cell.font = footer_font
        footer_cell.alignment = Alignment(horizontal="center", vertical="center")

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


