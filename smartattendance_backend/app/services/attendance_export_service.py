# app/services/attendance_export_service.py
"""
=============================================================================
SERVICIO: AttendanceExportService
=============================================================================
QUÉ HACE:
Genera reportes de asistencia en formatos universales (Excel XLSX y CSV con BOM UTF-8)
y calcula previsualizaciones estadísticas para el panel administrativo.

PARA QUÉ SIRVE:
Permite al equipo de Talento Humano y Nómina descargar informes detallados
de horas laboradas, entradas, descansos de almuerzo y horas extras para cualquier empresa.

PRINCIPIOS SOLID APLICADOS:
- S (Single Responsibility): Encapsula exclusivamente la lógica de exportación y formateo.
- D (Dependency Inversion): Depende de la sesión de base de datos inyectada.
=============================================================================
"""
from datetime import date
import io
import csv
from sqlalchemy.orm import Session
from app.models.user import User
from app.repositories.attendance_repository import AttendanceRepository
from app.services.sheets_service import SheetsService


class AttendanceExportService:
    """Servicio dedicado a la exportación de asistencias y cálculo de resúmenes ejecutivos."""

    def __init__(self, db: Session) -> None:
        self.db = db
        self._repo = AttendanceRepository(db)
        self._sheets_service = SheetsService(db)

    def export_excel(
        self,
        fecha_desde: date | None = None,
        fecha_hasta: date | None = None,
    ) -> bytes:
        """Genera un archivo Excel (.xlsx) estructurado y formateado con estilos corporativos."""
        records = self._repo.list_all(
            skip=0, limit=10000, fecha_desde=fecha_desde, fecha_hasta=fecha_hasta
        )
        return self._sheets_service.generate_excel_bytes(
            records, fecha_desde=fecha_desde, fecha_hasta=fecha_hasta,
        )

    def export_csv(
        self,
        fecha_desde: date | None = None,
        fecha_hasta: date | None = None,
    ) -> bytes:
        """Genera archivo plano CSV compatible con Microsoft Excel mediante BOM UTF-8."""
        records = self._repo.list_all(
            skip=0, limit=10000, fecha_desde=fecha_desde, fecha_hasta=fecha_hasta
        )
        output = io.StringIO()
        output.write('\ufeff')  # Byte Order Mark (BOM) para compatibilidad con Excel
        writer = csv.writer(output)
        writer.writerow([
            'Nombre', 'Cédula', 'Cargo/Área', 'Fecha', 'Entrada',
            'Salida Almuerzo', 'Regreso Almuerzo', 'Salida', 'Horas Totales', 'Estado'
        ])

        grouped, users_by_id = self._group_records_by_day(records)

        for (uid, rec_date) in sorted(grouped.keys()):
            u = users_by_id.get(uid)
            if not u:
                continue
            recs = sorted(grouped[(uid, rec_date)], key=lambda r: r.hora)
            times = {r.tipo: r.hora for r in recs}

            entrada = times['entrada'].strftime('%H:%M') if 'entrada' in times else '-'
            sal_alm = times['salida_almuerzo'].strftime('%H:%M') if 'salida_almuerzo' in times else '-'
            reg_alm = times['regreso_almuerzo'].strftime('%H:%M') if 'regreso_almuerzo' in times else '-'
            salida = times['salida'].strftime('%H:%M') if 'salida' in times else '-'

            secs = self._calculate_worked_seconds(times)
            h_str = f'{int(secs//3600)}h {int((secs%3600)//60):02d}m' if secs > 0 else '-'
            estado = 'Finalizado' if 'salida' in times else ('Trabajando' if 'entrada' in times else 'Ausente')

            writer.writerow([
                f'{u.nombre} {u.apellido}', u.cedula, u.cargo or 'General',
                rec_date.strftime('%d/%m/%Y'), entrada, sal_alm, reg_alm, salida, h_str, estado,
            ])
        return output.getvalue().encode('utf-8')

    def export_preview(
        self,
        fecha_desde: date | None = None,
        fecha_hasta: date | None = None,
    ) -> dict:
        """Calcula metadatos y muestras previas de datos sin sobrecargar la memoria."""
        records = self._repo.list_all(
            skip=0, limit=10000, fecha_desde=fecha_desde, fecha_hasta=fecha_hasta
        )
        unique_users = len({r.usuario_id for r in records})
        entradas = sum(1 for r in records if r.tipo == 'entrada')
        salidas = sum(1 for r in records if r.tipo in ('salida', 'salida_almuerzo', 'regreso_almuerzo'))

        grouped, users_by_id = self._group_records_by_day(records)
        sample = []
        for (uid, rec_date) in sorted(grouped.keys(), reverse=True)[:20]:
            u = users_by_id.get(uid)
            if not u:
                continue
            recs = sorted(grouped[(uid, rec_date)], key=lambda r: r.hora)
            times = {r.tipo: r.hora for r in recs}
            secs = self._calculate_worked_seconds(times)
            estado = 'salida' if 'salida' in times else ('entrada' if 'entrada' in times else 'ausente')

            sample.append({
                'nombre': f'{u.nombre} {u.apellido}',
                'cedula': u.cedula,
                'cargo': u.cargo,
                'fecha': rec_date.strftime('%d/%m/%Y'),
                'entrada': times['entrada'].strftime('%H:%M') if 'entrada' in times else None,
                'salida_almuerzo': times['salida_almuerzo'].strftime('%H:%M') if 'salida_almuerzo' in times else None,
                'regreso_almuerzo': times['regreso_almuerzo'].strftime('%H:%M') if 'regreso_almuerzo' in times else None,
                'salida': times['salida'].strftime('%H:%M') if 'salida' in times else None,
                'horas': f'{int(secs//3600)}h {int((secs%3600)//60):02d}m' if secs > 0 else '-',
                'estado': estado,
            })

        return {
            'total_registros': len(records),
            'empleados_unicos': unique_users,
            'entradas': entradas,
            'salidas': salidas,
            'tamano_estimado_xlsx': min(len(records) * 180, 5 * 1024 * 1024),
            'tamano_estimado_csv': len(records) * 120,
            'sample': sample,
        }

    # ── Métodos Privados Auxiliares ──────────────────────────────────────────
    def _group_records_by_day(self, records: list) -> tuple[dict, dict]:
        """Agrupa los registros por empleado y fecha."""
        grouped: dict[tuple[int, date], list] = {}
        user_ids = set()
        for r in records:
            key = (r.usuario_id, r.fecha)
            grouped.setdefault(key, []).append(r)
            user_ids.add(r.usuario_id)

        users_by_id = {
            u.id: u for u in self.db.query(User).filter(User.id.in_(user_ids)).all()
        } if user_ids else {}

        return grouped, users_by_id

    def _calculate_worked_seconds(self, times: dict) -> float:
        """Calcula el tiempo efectivo laborado descontando los descansos."""
        secs = 0.0
        ss = self._sheets_service
        if 'entrada' in times and 'salida_almuerzo' in times:
            d = (ss._as_datetime(times['salida_almuerzo']) - ss._as_datetime(times['entrada'])).total_seconds()
            if d > 0: secs += d
        elif 'entrada' in times and 'salida' in times and 'salida_almuerzo' not in times:
            d = (ss._as_datetime(times['salida']) - ss._as_datetime(times['entrada'])).total_seconds()
            if d > 0: secs += d

        if 'regreso_almuerzo' in times and 'salida' in times:
            d = (ss._as_datetime(times['salida']) - ss._as_datetime(times['regreso_almuerzo'])).total_seconds()
            if d > 0: secs += d

        if 'hora_extra_entrada' in times and 'hora_extra_salida' in times:
            d = (ss._as_datetime(times['hora_extra_salida']) - ss._as_datetime(times['hora_extra_entrada'])).total_seconds()
            if d > 0: secs += d

        return secs
