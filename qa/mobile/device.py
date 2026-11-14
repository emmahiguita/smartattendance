"""Controles reales del Android: selectores, esperas y fallos explícitos."""
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path
import uiautomator2 as u2

from android_environment import adb_path
ADB_EXE = adb_path()


def ensure_adb_online(serial):
    """Garantiza que el demonio ADB esté activo antes de conectar UIAutomator2."""
    from android_environment import detect_android
    detect_android(serial)


class Device:
    """Nunca da una acción por aprobada sin observar su estado final."""
    def __init__(self, serial, artifacts):
        from device_lease import acquire
        self._lease = acquire(serial)
        self.serial = serial
        ensure_adb_online(serial)
        self.d = u2.connect(serial)
        self.artifacts = Path(artifacts)
        self.artifacts.mkdir(parents=True, exist_ok=True)

    def tree(self):
        try:
            return ET.fromstring(self.d.dump_hierarchy())
        except OSError:
            self.d = u2.connect(self.serial)
            return ET.fromstring(self.d.dump_hierarchy())

    def labels(self):
        return [' '.join(filter(None, (n.get('content-desc'),
                None if n.get('class') == 'android.widget.EditText' else n.get('text'), n.get('hint'))))
                for n in self.tree().iter('node')]

    def wait(self, predicate, message, seconds=20):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            if predicate():
                return
            time.sleep(.35)
        raise AssertionError(message)

    def visible(self, label, exact=False):
        return any(label == x if exact else label in x for x in self.labels())

    def expect(self, label, seconds=20):
        self.wait(lambda: self.visible(label), 'No apareció: ' + label, seconds)

    def tap(self, label, exact=False):
        """Prioriza selector; usa límites actuales del mismo elemento si falla."""
        self.wait(lambda: self.visible(label, exact), 'No se encontró: ' + label)
        selector = self.d(description=label) if exact else self.d(descriptionContains=label)
        try:
            selector.click(timeout=2)
            return
        except u2.exceptions.UiObjectNotFoundError:
            pass
        nodes = [n for n in self.tree().iter('node')
                 if (label == (n.get('content-desc') or n.get('text')) if exact else
                     label in (n.get('content-desc') or n.get('text', '')))]
        assert nodes, 'Elemento desapareció: ' + label
        x1, y1, x2, y2 = map(int, re.findall(r'\d+', nodes[-1].get('bounds')))
        self.d.click((x1 + x2) // 2, (y1 + y2) // 2)

    def hide_keyboard(self):
        """QUÉ HACE: Oculta el teclado virtual de Android solo si está visible en pantalla."""
        try:
            state = self.d.shell('dumpsys input_method').output
            if re.search(r'mInputShown=true', state):
                self.d.press('back')
                time.sleep(.35)
        except OSError:
            return

    def reveal(self, label, attempts=6):
        self.hide_keyboard()
        for _ in range(attempts):
            if self.visible(label):
                return
            self.hide_keyboard()
            self.d.swipe_ext('up', scale=.55)
        raise AssertionError('No se encontró al desplazar: ' + label)

    def fill(self, label, value, index=None):
        """Etiqueta accesible; índice solo cuando se verificó el formulario."""
        deadline = time.monotonic() + 10
        nodes = []
        while time.monotonic() < deadline:
            nodes = [n for n in self.tree().iter('node')
                     if n.get('class') == 'android.widget.EditText']
            if nodes:
                break
            time.sleep(0.4)
        assert nodes, f'No se encontraron campos de texto (EditText) en pantalla para: {label}'
        matches = [n for n in nodes if label in ' '.join(
            n.get(k, '') for k in ('text', 'content-desc', 'hint'))]
        if not matches and index is None:
            self.reveal(label)
            nodes = [n for n in self.tree().iter('node')
                     if n.get('class') == 'android.widget.EditText']
            matches = [n for n in nodes if label in ' '.join(
                n.get(k, '') for k in ('text', 'content-desc', 'hint'))]
            assert matches, 'Campo sin etiqueta accesible: ' + label
        target = matches[0] if matches else nodes[index]
        x1, y1, x2, y2 = map(int, re.findall(r'\d+', target.get('bounds')))
        self.d.click((x1 + x2) // 2, (y1 + y2) // 2)
        field = self.d(className='android.widget.EditText', focused=True)
        assert field.exists, 'El campo no recibió el foco: ' + label
        field.set_text(value)
        self.hide_keyboard()

    def screenshot(self, name):
        self.d.screenshot(str(self.artifacts / (name + '.png')))

    def back(self):
        self.d.press('back')
