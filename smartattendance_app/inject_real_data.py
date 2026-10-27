import sqlite3
import uuid
import json
import subprocess
import os

def generate_data():
    conn_p = sqlite3.connect('temp_photo.db')
    c_p = conn_p.cursor()

    workers = [
        (1, 'Emmanuel Higuita', '1007331963', 'Encargado local / Administrador', 1, 'Emmanuel', 'Higuita'),
        (2, 'Juan Pérez', '1234567890', 'Operario de Planta', 1, 'Juan', 'Pérez'),
        (3, 'María Gómez', '0987654321', 'Supervisora de Campo', 1, 'María', 'Gómez'),
        (4, 'Carlos Ruiz', '1122334455', 'Conductor Operativo', 1, 'Carlos', 'Ruiz'),
        (5, 'Sofía Mendoza', '5544332211', 'Técnica de Redes', 1, 'Sofía', 'Mendoza'),
    ]

    sched_json = json.dumps({
        'minutes': 480,
        'deduct': True,
        'nightStart': 1140,
        'nightEnd': 360,
        'name': 'Turno Diurno Operativo',
        'start': 480,
        'end': 1050,
        'markStart': 420,
        'markEnd': 1140,
        'weekdays': [1, 2, 3, 4, 5]
    })

    # Update or insert workers
    for w_id, name, doc, job, crew_id, nom, ape in workers:
        c_p.execute('''
            INSERT OR REPLACE INTO workers (id, name, document, job, crew_id, schedule_json, authorization_reference, authorization_policy, authorization_at)
            VALUES (?, ?, ?, ?, ?, ?, 'Registro oficial de personal', 'Política General SmartAttendance', '2026-10-26T08:00:00Z')
        ''', (w_id, name, doc, job, crew_id, sched_json))

    # Clean old photo marks and journeys for fresh clean real data
    c_p.execute('DELETE FROM photo_marks')
    c_p.execute('DELETE FROM journeys')

    # Days: 2026-10-24 (Friday) and 2026-10-26 (Monday)
    days = [
        ('2026-10-24', [
            # w_id, e_h, e_m, e_s, sa_h, sa_m, sa_s, ra_h, ra_m, ra_s, s_h, s_m, s_s
            (1, 7, 52, 10, 12, 5, 30, 13, 4, 15, 17, 18, 40),
            (2, 7, 56, 45, 12, 12, 10, 13, 10, 20, 17, 7, 15),
            (3, 8, 1, 20, 12, 18, 40, 13, 15, 50, 17, 24, 10),
            (4, 7, 46, 30, 12, 2, 15, 13, 3, 40, 17, 12, 25),
            (5, 8, 3, 15, 12, 22, 10, 13, 20, 5, 17, 31, 50),
        ]),
        ('2026-10-26', [
            (1, 7, 50, 12, 12, 4, 10, 13, 2, 5, 17, 16, 20),
            (2, 7, 54, 30, 12, 9, 45, 13, 8, 15, 17, 5, 40),
            (3, 8, 0, 15, 12, 15, 20, 13, 14, 10, 17, 20, 30),
            (4, 7, 44, 50, 12, 1, 10, 13, 1, 30, 17, 9, 15),
            (5, 8, 2, 40, 12, 21, 35, 13, 19, 45, 17, 30, 10),
        ]),
    ]

    base_lat = 6.2874
    base_lon = -75.5871

    # Connect to offline db too
    conn_o = sqlite3.connect('temp_offline.db')
    c_o = conn_o.cursor()
    c_o.execute('DELETE FROM attendance_history')

    for date_str, worker_times in days:
        for w_id, eh, em, es, sah, sam, sas, rah, ram, ras, sh, sm, ss in worker_times:
            w_info = next(w for w in workers if w[0] == w_id)
            name, doc, job, nom, ape = w_info[1], w_info[2], w_info[3], w_info[5], w_info[6]

            j_id = f"journey_{doc}_{date_str.replace('-', '')}"
            c_p.execute('''
                INSERT INTO journeys (id, worker_id, work_date, schedule_json, status, reviewed_by, reviewed_at, approved_seconds, review_note, operator_document, crew_name, zone_name)
                VALUES (?, ?, ?, ?, 'closed', '1007331963', ?, 28800, 'Jornada completa y validada', '1007331963', 'Equipo Operativo Central', 'Sede Principal Operativa')
            ''', (j_id, w_id, date_str, sched_json, f"{date_str}T18:00:00Z"))

            # 4 marks per worker per day
            marks_meta = [
                ('entrada', eh, em, es, 'ENTRADA'),
                ('salida_almuerzo', sah, sam, sas, 'SALIDA_ALMUERZO'),
                ('regreso_almuerzo', rah, ram, ras, 'REGRESO_ALMUERZO'),
                ('salida', sh, sm, ss, 'SALIDA'),
            ]

            for m_type, h, m, s, offline_type in marks_meta:
                m_uuid = str(uuid.uuid4())
                # Colombia time is UTC-5 -> UTC = Colombia + 5h
                utc_h = h + 5
                utc_iso = f"{date_str}T{utc_h:02d}:{m:02d}:{s:02d}.000Z"
                col_time_str = f"{h:02d}:{m:02d}:{s:02d}"

                lat = base_lat + (w_id * 0.0001)
                lon = base_lon + (w_id * 0.0001)

                c_p.execute('''
                    INSERT INTO photo_marks (uuid, worker_id, name, document, job, type, captured_at, local_path, latitude, longitude, accuracy_m, location_at, journey_id, operator_document)
                    VALUES (?, ?, ?, ?, ?, ?, ?, '', ?, ?, 10.5, ?, ?, '1007331963')
                ''', (m_uuid, w_id, name, doc, job, m_type, utc_iso, lat, lon, utc_iso, j_id))

                # Insert into attendance_history (smartattendance_offline)
                c_o.execute('''
                    INSERT INTO attendance_history (usuario_id, tipo, fecha, hora, latitud, longitud, direccion, nombre, apellido, cedula, cargo, created_at)
                    VALUES (?, ?, ?, ?, ?, ?, 'Calle 25 # 20-30, Dosquebradas, Risaralda', ?, ?, ?, ?, ?)
                ''', (w_id, offline_type, date_str, col_time_str, lat, lon, nom, ape, doc, job, utc_iso))

    # Also update usuarios_locales in smartattendance_offline
    for w_id, name, doc, job, crew_id, nom, ape in workers:
        is_adm = 1 if doc == '1007331963' else 0
        c_o.execute('''
            INSERT OR REPLACE INTO usuarios_locales (id, cedula, nombre, apellido, correo, cargo, is_admin, direccion)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'Calle 25 # 20-30, Dosquebradas, Risaralda')
        ''', (w_id, doc, nom, ape, f"{nom.lower()}@smartattendance.co", job, is_adm))

    conn_p.commit()
    conn_o.commit()

    print(f"Data generation complete.")
    p_marks = c_p.execute('SELECT COUNT(*) FROM photo_marks').fetchone()[0]
    p_journeys = c_p.execute('SELECT COUNT(*) FROM journeys').fetchone()[0]
    o_history = c_o.execute('SELECT COUNT(*) FROM attendance_history').fetchone()[0]
    o_users = c_o.execute('SELECT COUNT(*) FROM usuarios_locales').fetchone()[0]

    print(f"local_photo_attendance: {p_marks} marcas, {p_journeys} jornadas.")
    print(f"smartattendance_offline: {o_history} registros de historial, {o_users} usuarios locales.")

    conn_p.close()
    conn_o.close()

if __name__ == '__main__':
    generate_data()
