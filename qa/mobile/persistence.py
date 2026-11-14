"""Lee copias de las bases reales; nunca escribe datos en el teléfono."""
import sqlite3
import subprocess
import tempfile
from pathlib import Path

PACKAGE = 'io.smartattendance.attendance'


def rows(serial, database, sql, args=()):
    """Copia DB y WAL a una carpeta temporal para consultar una instantánea."""
    with tempfile.TemporaryDirectory(prefix='attendance_read_', ignore_cleanup_errors=True) as temp:
        path = Path(temp) / database
        for suffix in ('', '-wal', '-shm'):
            command = ['adb', '-s', serial, 'exec-out', 'run-as', PACKAGE,
                       'cat', 'databases/' + database + suffix]
            result = subprocess.run(command, capture_output=True, timeout=15)
            if result.returncode or not result.stdout:
                if not suffix:
                    raise RuntimeError('No se pudo leer la base de datos instalada: ' + database)
                continue
            Path(str(path) + suffix).write_bytes(result.stdout)
        db = sqlite3.connect(path)
        try:
            db.row_factory = sqlite3.Row
            return [dict(row) for row in db.execute(sql, args).fetchall()]
        finally:
            db.close()


def worker(serial, document):
    found = rows(serial, 'local_photo_attendance.db',
        'SELECT w.document,w.name,w.job,w.crew_id,w.schedule_json,c.supervisor_document,c.zone_id '
        'FROM workers w LEFT JOIN crews c ON c.id=w.crew_id WHERE w.document=?', (document,))
    assert len(found) == 1, 'El alta no existe exactamente una vez'
    accounts = rows(serial, 'smartattendance_offline.db',
        'SELECT cedula,cargo,is_admin FROM usuarios_locales WHERE cedula=?', (document,))
    assert len(accounts) == 1, 'La cuenta de acceso no existe exactamente una vez'
    return found[0], accounts[0]
