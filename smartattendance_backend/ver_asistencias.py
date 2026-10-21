# smartattendance_backend/ver_asistencias.py
"""
Script didáctico y directo para consultar los registros de asistencia de los trabajadores
directamente desde la base de datos de SmartAttendance.
"""
import sys
import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).parent / "smartattendance.db"

def consultar_asistencias(limite: int = 20, cedula: str = ""):
    if not DB_PATH.exists():
        print(f"Error: Base de datos no encontrada en {DB_PATH}")
        return

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    query = """
    SELECT 
        a.id,
        u.nombre || ' ' || u.apellido AS empleado,
        u.cedula,
        u.cargo,
        a.tipo,
        a.fecha,
        a.hora,
        COALESCE(a.direccion, 'Posición GPS registrada') AS direccion
    FROM attendance a
    JOIN users u ON a.usuario_id = u.id
    """
    params = []
    if cedula:
        query += " WHERE u.cedula LIKE ?"
        params.append(f"%{cedula}%")
    query += " ORDER BY a.id DESC LIMIT ?"
    params.append(limite)

    cur.execute(query, params)
    rows = cur.fetchall()
    conn.close()

    print("=" * 105)
    print("            SMARTATTENDANCE - REGISTRO DE TRABAJADORES EN TIEMPO REAL             ")
    print("=" * 105)

    if not rows:
        print(">> No hay registros de asistencia en la base de datos todavía.")
        print(">> Abre la app móvil o haz login y marca tu asistencia para verla reflejada aquí.")
    else:
        header = f"{'ID':<4} | {'EMPLEADO':<22} | {'CEDULA':<12} | {'TIPO':<16} | {'FECHA':<10} | {'HORA':<8} | {'DIRECCIÓN'}"
        print(header)
        print("-" * 105)
        for r in rows:
            line = f"{r[0]:<4} | {r[1][:22]:<22} | {r[2]:<12} | {r[4]:<16} | {str(r[5])[:10]:<10} | {str(r[6])[:8]:<8} | {r[7]}"
            print(line)

    print("=" * 105)
    print("Servidor Backend Activo: http://127.0.0.1:8000")
    print("Documentación Swagger:   http://127.0.0.1:8000/docs")
    print("=" * 105)

if __name__ == "__main__":
    limite = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 20
    cedula = sys.argv[2] if len(sys.argv) > 2 else ""
    consultar_asistencias(limite, cedula)
