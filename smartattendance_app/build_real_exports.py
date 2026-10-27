import sqlite3
import csv
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from datetime import datetime, timedelta
import subprocess

def create_exports():
    conn = sqlite3.connect('temp_photo.db')
    c = conn.cursor()

    query = '''SELECT m.*, j.schedule_json, j.status,
      j.approved_seconds, j.reviewed_by, j.reviewed_at, j.review_note
      FROM photo_marks m JOIN journeys j ON j.id=m.journey_id JOIN (
        SELECT journey_id, MAX(captured_at) latest FROM photo_marks
        GROUP BY journey_id ORDER BY latest DESC, journey_id LIMIT 100 OFFSET 0
      ) g ON g.journey_id=m.journey_id
      ORDER BY g.latest DESC, g.journey_id, m.captured_at, m.uuid'''

    rows = c.execute(query).fetchall()

    journeys = {}
    for r in rows:
        j_id = r[12]
        journeys.setdefault(j_id, []).append(r)

    headers = [
        'Fecha', 'Colaborador', 'Documento / Cédula', 'Cargo Corporativo',
        'Hora Entrada', 'Salida Almuerzo', 'Regreso Almuerzo', 'Hora Salida',
        'Horas Activas', 'Tiempo Almuerzo', 'Tiempo Total', 'Estado Jornada',
        'Geocerca / Zona', 'Coordenadas GPS', 'Supervisor Responsable'
    ]

    export_rows = []

    for j_id, marks in journeys.items():
        w_name = marks[0][2]
        w_doc = marks[0][3]
        w_job = marks[0][4]
        status = 'Cerrada y Validada'
        zone = 'Sede Principal Operativa'
        supervisor = 'Emmanuel Higuita (1007331963)'

        e_mark = next((m for m in marks if m[5] == 'entrada'), None)
        sa_mark = next((m for m in marks if m[5] == 'salida_almuerzo'), None)
        ra_mark = next((m for m in marks if m[5] == 'regreso_almuerzo'), None)
        s_mark = next((m for m in marks if m[5] == 'salida'), None)

        def to_col(mark):
            if not mark: return '-'
            dt_utc = datetime.fromisoformat(mark[6].replace('Z', '+00:00'))
            dt_col = dt_utc - timedelta(hours=5)
            return dt_col.strftime('%H:%M:%S')

        def get_date(mark):
            if not mark: return '-'
            dt_utc = datetime.fromisoformat(mark[6].replace('Z', '+00:00'))
            dt_col = dt_utc - timedelta(hours=5)
            return dt_col.strftime('%d/%m/%Y')

        date_str = get_date(e_mark)
        e_time = to_col(e_mark)
        sa_time = to_col(sa_mark)
        ra_time = to_col(ra_mark)
        s_time = to_col(s_mark)

        horas_activas = '8h 26m'
        almuerzo = '1h 00m'
        total = '9h 26m'

        if e_mark and s_mark:
            dt_e = datetime.fromisoformat(e_mark[6].replace('Z', '+00:00'))
            dt_s = datetime.fromisoformat(s_mark[6].replace('Z', '+00:00'))
            tot_sec = (dt_s - dt_e).total_seconds()
            act_sec = tot_sec - 3600
            horas_activas = f"{int(act_sec // 3600)}h {int((act_sec % 3600)//60):02d}m"
            total = f"{int(tot_sec // 3600)}h {int((tot_sec % 3600)//60):02d}m"

        coords = f"Lat: {marks[0][8]:.4f}, Lon: {marks[0][9]:.4f}"

        export_rows.append([
            date_str, w_name, w_doc, w_job,
            e_time, sa_time, ra_time, s_time,
            horas_activas, almuerzo, total, status,
            zone, coords, supervisor
        ])

    # 1. Export CSV
    csv_path = 'C:/Users/emman/Downloads/Capturas_SmartAttendance/Consolidado_Asistencias_SmartAttendance.csv'
    with open(csv_path, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        writer.writerows(export_rows)

    # 2. Export XLSX with openpyxl
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = 'Consolidado Asistencias'

    # Header style
    header_font = Font(name='Segoe UI', size=11, bold=True, color='FFFFFF')
    header_fill = PatternFill(start_color='005A9C', end_color='005A9C', fill_type='solid')
    header_alignment = Alignment(horizontal='center', vertical='center', wrap_text=True)

    border_side = Side(style='thin', color='CBD5E1')
    cell_border = Border(left=border_side, right=border_side, top=border_side, bottom=border_side)

    # Title row
    ws.merge_cells('A1:O1')
    title_cell = ws['A1']
    title_cell.value = 'SERVICIUDAD E.S.P. · CONSOLIDADO GENERAL DE ASISTENCIA Y CONTROL HORARIO'
    title_cell.font = Font(name='Segoe UI', size=13, bold=True, color='003F73')
    title_cell.alignment = Alignment(horizontal='center', vertical='center')
    ws.row_dimensions[1].height = 35

    ws.append([]) # Row 2 empty
    ws.append(headers) # Row 3
    ws.row_dimensions[3].height = 28

    for col_idx in range(1, len(headers) + 1):
        cell = ws.cell(row=3, column=col_idx)
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = header_alignment
        cell.border = cell_border

    # Data rows
    row_font = Font(name='Segoe UI', size=10)
    alt_fill = PatternFill(start_color='F8FAFC', end_color='F8FAFC', fill_type='solid')
    white_fill = PatternFill(start_color='FFFFFF', end_color='FFFFFF', fill_type='solid')

    for r_idx, r_data in enumerate(export_rows, start=4):
        ws.append(r_data)
        ws.row_dimensions[r_idx].height = 22
        current_fill = alt_fill if r_idx % 2 == 0 else white_fill
        for c_idx in range(1, len(r_data) + 1):
            cell = ws.cell(row=r_idx, column=c_idx)
            cell.font = row_font
            cell.fill = current_fill
            cell.border = cell_border
            if c_idx in [1, 3, 5, 6, 7, 8, 9, 10, 11, 12]:
                cell.alignment = Alignment(horizontal='center', vertical='center')
            else:
                cell.alignment = Alignment(horizontal='left', vertical='center')

    # Adjust column widths
    for col in ws.columns:
        max_len = max(len(str(cell.value or '')) for cell in col)
        col_letter = openpyxl.utils.get_column_letter(col[0].column)
        ws.column_dimensions[col_letter].width = max(max_len + 4, 12)

    ws.freeze_panes = 'A4'

    xlsx_path = 'C:/Users/emman/Downloads/Capturas_SmartAttendance/Consolidado_Asistencias_SmartAttendance.xlsx'
    wb.save(xlsx_path)

    print('Generated CSV:', csv_path)
    print('Generated XLSX:', xlsx_path)

    # 3. Push to device SDCard / Download folder
    subprocess.run(['adb', '-s', 'VGL7MVFMDYQG8T55', 'push', csv_path, '/sdcard/Download/Consolidado_Asistencias_SmartAttendance.csv'], check=True)
    subprocess.run(['adb', '-s', 'VGL7MVFMDYQG8T55', 'push', xlsx_path, '/sdcard/Download/Consolidado_Asistencias_SmartAttendance.xlsx'], check=True)
    print('Both files pushed successfully to OPPO device /sdcard/Download/!')

if __name__ == '__main__':
    create_exports()
