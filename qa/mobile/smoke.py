"""Preflight y prueba de navegación con evidencias y reporte JUnit real."""
import json
import os
import time
import xml.etree.ElementTree as ET
from pathlib import Path
from android_environment import detect_android, command


def execute(stage, requested=None):
    folder = Path(os.getenv('SA_REPORT_DIR', str(Path(os.getenv('LOCALAPPDATA', str(Path.home())))/'SmartAttendanceQA')))
    folder = folder / ('automation_'+str(time.time_ns()))
    folder.mkdir(parents=True)
    suite = ET.Element('testsuite', name='Android '+stage, tests='1', failures='0')
    case = ET.SubElement(suite, 'testcase', name=stage)
    report = {'passed': False, 'stage': stage}
    try:
        serial = detect_android(requested)
        report['serial'] = serial
        assert 'package:' in command('shell', 'pm', 'path', 'io.smartattendance.attendance', serial=serial), 'App no instalada'
        report['model'] = command('shell', 'getprop', 'ro.product.model', serial=serial).strip()
        report['android'] = command('shell', 'getprop', 'ro.build.version.release', serial=serial).strip()
        if stage == 'smoke':
            from device import Device
            ui = Device(serial, folder)
            ui.d.screen_on()
            ui.d.app_start('io.smartattendance.attendance')
            ui.wait(lambda: ui.visible('Perfil', exact=True) or ui.visible('Iniciar sesión') or ui.visible('Ingresar como Administrador') or ui.visible('Registrar Personal') or ui.visible('Registrar Operario'), 'La app no llegó a un estado reconocido', seconds=30)
            if ui.visible('Perfil', exact=True):
                report['screen'] = 'navigation'
                ui.tap('Perfil', exact=True)
                ui.expect('Editar perfil')
                ui.screenshot('profile')
                ui.tap('Inicio', exact=True)
                ui.expect('Inicio')
            elif ui.visible('Registrar Personal') or ui.visible('Registrar Operario'):
                report['screen'] = 'registration-preserved'
                ui.expect('Guardar')
                ui.expect('Rol / Nivel de acceso')
            else:
                report['screen'] = 'login'
                ui.expect('Contraseña')
            ui.screenshot('smoke')
        report['passed'] = True
        print('PASS: '+stage+' en '+serial)
        return 0
    except Exception as error:
        suite.set('failures', '1')
        ET.SubElement(case, 'failure', message=str(error)).text = str(error)
        report['error'] = str(error)
        print('FAIL: '+str(error))
        return 1
    finally:
        (folder/'result.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
        ET.ElementTree(suite).write(folder/'junit.xml', encoding='utf-8', xml_declaration=True)
        print('Evidencia: '+str(folder))
