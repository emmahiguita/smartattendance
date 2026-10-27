import sqlite3
from datetime import datetime, timezone, timedelta

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

print(f"TOTAL JOURNEYS (Dias): {len(journeys)}")
print(f"TOTAL MARCAS: {len(rows)}")

table_sample = []
entradas = 0
salidas = 0
unique_docs = set()

for j_id, marks in journeys.items():
    worker_name = marks[0][2]
    worker_doc = marks[0][3]
    worker_job = marks[0][4]
    status = marks[0][15]
    
    unique_docs.add(worker_doc)
    
    e_mark = next((m for m in marks if m[5] == 'entrada'), None)
    s_mark = next((m for m in marks if m[5] == 'salida'), None)
    
    if e_mark: entradas += 1
    if s_mark: salidas += 1
    
    e_time_str = '-'
    s_time_str = '-'
    horas_str = '-'
    date_str = '-'
    
    if e_mark:
        dt_utc = datetime.fromisoformat(e_mark[6].replace('Z', '+00:00'))
        dt_col = dt_utc - timedelta(hours=5)
        date_str = dt_col.strftime('%d/%m/%Y')
        e_time_str = dt_col.strftime('%H:%M')
    
    if s_mark:
        dt_utc = datetime.fromisoformat(s_mark[6].replace('Z', '+00:00'))
        dt_col = dt_utc - timedelta(hours=5)
        s_time_str = dt_col.strftime('%H:%M')
        
    if e_mark and s_mark:
        dt_e = datetime.fromisoformat(e_mark[6].replace('Z', '+00:00'))
        dt_s = datetime.fromisoformat(s_mark[6].replace('Z', '+00:00'))
        active_secs = (dt_s - dt_e).total_seconds() - 3600
        h = int(active_secs // 3600)
        m = int((active_secs % 3600) // 60)
        horas_str = f"{h}h {m:02d}m"
        
    table_sample.append({
        'nombre': worker_name,
        'cedula': worker_doc,
        'cargo': worker_job,
        'fecha': date_str,
        'entrada': e_time_str,
        'salida': s_time_str,
        'horas': horas_str,
        'estado': status,
    })

print(f"Empleados únicos: {len(unique_docs)}")
print(f"Entradas: {entradas}, Salidas: {salidas}\n")
print(f"{'Colaborador':<18} | {'Cédula':<10} | {'Cargo':<25} | {'Fecha':<10} | {'Entrada':<7} | {'Salida':<7} | {'Horas':<7} | {'Estado':<6}")
print("-" * 105)
for row in table_sample:
    print(f"{row['nombre']:<18} | {row['cedula']:<10} | {row['cargo']:<25} | {row['fecha']:<10} | {row['entrada']:<7} | {row['salida']:<7} | {row['horas']:<7} | {row['estado']:<6}")
