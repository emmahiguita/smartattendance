"""
seed.py — Populate the database with test data.
Run once: python seed.py
"""
import sys
import os

# Ensure app is importable
sys.path.insert(0, os.path.dirname(__file__))

from datetime import datetime, timezone, timedelta, date, time
from app.database.base import engine, SessionLocal, create_all_tables
from app.models.user import User
from app.models.attendance import Attendance
from app.models.qr_code import QRCode


USERS_SEED = [
    {"nombre": "Juan",     "apellido": "Pérez",    "cedula": "1234567890", "correo": "juan@empresa.co",    "cargo": "Desarrollador Senior", "fecha_nacimiento": "1992-05-15", "telefono": "+57 300 123 4567", "direccion": "Calle 45 # 12-34, Bogotá"},
    {"nombre": "María",    "apellido": "García",   "cedula": "0987654321", "correo": "maria@empresa.co",   "cargo": "Diseñadora UX",         "fecha_nacimiento": "1995-09-22", "telefono": "+57 311 987 6543", "direccion": "Carrera 7 # 85-20, Medellín"},
    {"nombre": "Carlos",   "apellido": "López",    "cedula": "1122334455", "correo": "carlos@empresa.co",  "cargo": "Gerente de Proyectos", "fecha_nacimiento": "1988-12-04", "telefono": "+57 320 555 1212", "direccion": "Av. El Poblado # 10-50, Medellín"},
    {"nombre": "Sofía",    "apellido": "Martínez", "cedula": "5544332211", "correo": "sofia@empresa.co",   "cargo": "Analista de Datos",     "fecha_nacimiento": "1998-03-30", "telefono": "+57 315 444 3322", "direccion": "Calle 100 # 15-60, Bogotá"},
    {"nombre": "Andrés",   "apellido": "Torres",   "cedula": "6677889900", "correo": "andres@empresa.co",  "cargo": "DevOps Engineer",      "fecha_nacimiento": "1993-11-18", "telefono": "+57 301 777 8899", "direccion": "Transversal 23 # 45-12, Cali"},
    {"nombre": "Emmanuel", "apellido": "Usuario",  "cedula": "1007331963", "correo": "emmanuel@empresa.co", "cargo": "Administrador",       "fecha_nacimiento": "1996-07-20", "telefono": "+57 310 888 9900", "direccion": "Calle 26 # 68-90, Bogotá"},
]


def seed() -> None:
    print("[*] Creando tablas...")
    create_all_tables()

    db = SessionLocal()
    try:
        # Skip if already seeded
        if db.query(User).count() > 0:
            print("[OK] Base de datos ya tiene datos. Omitiendo seed.")
            return

        print("[*] Insertando usuarios...")
        users: list[User] = []
        for u in USERS_SEED:
            user = User(**u)
            db.add(user)
            users.append(user)
        db.commit()
        for u in users:
            db.refresh(u)

        print("[*] Insertando registros de asistencia...")
        today = date.today()
        records = []
        for i, user in enumerate(users):
            # Entry today
            records.append(Attendance(
                usuario_id=user.id,
                fecha=today,
                hora=time(8 + i % 2, 15 + (i * 7) % 30),
                tipo="entrada",
            ))
            # Exit yesterday
            yesterday = today - timedelta(days=1)
            records.append(Attendance(
                usuario_id=user.id,
                fecha=yesterday,
                hora=time(8, 0 + i * 5),
                tipo="entrada",
            ))
            records.append(Attendance(
                usuario_id=user.id,
                fecha=yesterday,
                hora=time(17, 30 + i % 10),
                tipo="salida",
            ))

        for r in records:
            db.add(r)
        db.commit()

        print("[*] Generando QR codes de demo...")
        import uuid
        for user in users[:2]:
            qr = QRCode(codigo=str(uuid.uuid4()), usuario_id=user.id)
            db.add(qr)
        db.commit()

        print("\n[OK] Seed completado exitosamente.")
        print("[*] Usuarios de prueba:")
        for u in USERS_SEED:
            print(f"   • {u['nombre']} {u['apellido']} — cédula: {u['cedula']}")

    finally:
        db.close()


if __name__ == "__main__":
    seed()
