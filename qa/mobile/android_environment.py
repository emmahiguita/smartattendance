"""Detección Android sin seriales ni rutas de SDK ligados a un equipo."""
import os
import shutil
import subprocess
from pathlib import Path


def adb_path():
    candidates = [os.getenv('SA_ADB_PATH'), shutil.which('adb')]
    for variable in ('ANDROID_SDK_ROOT', 'ANDROID_HOME'):
        if os.getenv(variable):
            candidates.append(str(Path(os.environ[variable])/'platform-tools/adb.exe'))
    candidates.append(str(Path.home()/'AppData/Local/Android/Sdk/platform-tools/adb.exe'))
    for candidate in candidates:
        if candidate and Path(candidate).is_file():
            return str(candidate)
    raise RuntimeError('No se encontró ADB. Configura ANDROID_SDK_ROOT o SA_ADB_PATH.')


def command(*args, serial=None):
    result = subprocess.run([adb_path(), *(['-s', serial] if serial else []), *args],
                            capture_output=True, text=True, timeout=25)
    if result.returncode:
        raise RuntimeError('ADB falló: '+result.stderr.strip())
    return result.stdout


def detect_android(requested=None):
    command('start-server')
    devices = []
    for line in command('devices', '-l').splitlines()[1:]:
        fields = line.split()
        if len(fields) >= 2:
            devices.append((fields[0], fields[1]))
    requested = requested or os.getenv('SA_DEVICE_SERIAL')
    if requested:
        if (requested, 'device') not in devices:
            raise RuntimeError('El dispositivo seleccionado no está conectado y autorizado.')
        return requested
    ready = [serial for serial, status in devices if status == 'device']
    if len(ready) > 1:
        raise RuntimeError('Hay varios Android. Selecciona uno mediante SA_DEVICE_SERIAL.')
    if not ready:
        raise RuntimeError('No hay Android autorizado. Conecta, desbloquea y acepta depuración USB. Estados: '+str(devices))
    return ready[0]
