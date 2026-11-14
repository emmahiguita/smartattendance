"""Ejecutor de Katalon/terminal: éxito solo si las aserciones reales pasan."""
import argparse
import json
import os
import secrets
import sys
import time
import traceback
from pathlib import Path
from device import Device
from flows import admin_stage, supervisor_stage, edit_stage

REAL_COLOMBIAN_ROSTER = [
    {"name": "Gonzalo Alberto Morales Gómez", "prefix": "10882"},
    {"name": "Carlos Andrés Restrepo Henao", "prefix": "10883", "role": "Operador"},
    {"name": "María Fernanda Valencia Castaño", "prefix": "10884", "role": "Colaborador"},
    {"name": "Jorge Eliécer Bermúdez Osorio", "prefix": "10885", "role": "Operario"},
    {"name": "Diana Marcela Jaramillo Morales", "prefix": "10886", "role": "Promotor"},
    {"name": "Luis Fernando Quintero Cardona", "prefix": "10887", "role": "Conductor"},
]


def run():
    parser = argparse.ArgumentParser()
    parser.add_argument('--stage', choices=['preflight', 'smoke', 'admin', 'supervisor', 'edit', 'all'], default='smoke')
    parser.add_argument('--serial', default=os.getenv('SA_DEVICE_SERIAL'))
    args = parser.parse_args()
    if args.stage in ('preflight', 'smoke'):
        from smoke import execute
        return execute(args.stage, args.serial)
    from android_environment import detect_android
    args.serial = detect_android(args.serial)
    if args.stage in ('admin', 'all') and not all(os.getenv(k) for k in ('SA_ADMIN_DOCUMENT', 'SA_ADMIN_PASSWORD')):
        raise RuntimeError('Configura SA_ADMIN_DOCUMENT y SA_ADMIN_PASSWORD fuera del código antes de crear datos.')
    folder = Path(os.getenv('LOCALAPPDATA', str(Path.home()))) / 'SmartAttendanceQA'
    folder.mkdir(exist_ok=True)
    state_path = folder / 'private_run_state.json'
    if args.stage in ('admin', 'all') or not state_path.exists():
        suffix = str(time.time_ns())[-5:]
        sup_data = REAL_COLOMBIAN_ROSTER[0]
        workers_data = [
            {
                'name': p['name'],
                'doc': p['prefix'] + suffix,
                'role': p['role'],
            }
            for p in REAL_COLOMBIAN_ROSTER[1:]
        ]
        base_id = '99' + suffix
        state = {
            'run': base_id,
            'supervisor': sup_data['prefix'] + suffix,
            'name': sup_data['name'],
            'crew': 'Cuadrilla Central ' + suffix,
            'supervisor_crew': 'Equipo Sup ' + suffix,
            'site_name': 'Sede Dosquebradas ' + suffix,
            'site_address': 'Calle 25 # 20-30, Dosquebradas',
            'workers': [w['doc'] for w in workers_data],
            'workers_data': workers_data,
            'positions': [w['role'] for w in workers_data],
            'password': 'Qa!' + secrets.token_hex(6) + 'A7',
        }
        state_path.write_text(json.dumps(state), encoding='utf-8')
    else:
        state = json.loads(state_path.read_text(encoding='utf-8'))
        if 'workers_data' not in state:
            state['workers_data'] = [
                {'name': 'Carlos Andrés Restrepo Henao', 'doc': state['workers'][0], 'role': 'Operador'},
                {'name': 'María Fernanda Valencia Castaño', 'doc': state['workers'][1], 'role': 'Colaborador'},
                {'name': 'Jorge Eliécer Bermúdez Osorio', 'doc': state['workers'][2], 'role': 'Operario'},
                {'name': 'Diana Marcela Jaramillo Morales', 'doc': state['workers'][3], 'role': 'Promotor'},
                {'name': 'Luis Fernando Quintero Cardona', 'doc': state['workers'][4], 'role': 'Conductor'},
            ]
    artifacts = Path(os.getenv('SA_REPORT_DIR', str(folder))) / ('evidence_' + state['run'])
    ui = Device(args.serial, artifacts)
    result = {'run': state['run'], 'device': args.serial, 'stages': []}
    try:
        if args.stage in ('admin', 'all'):
            credentials = {
                'document': os.environ['SA_ADMIN_DOCUMENT'],
                'password': os.environ['SA_ADMIN_PASSWORD'],
            }
            admin_stage(ui, state, credentials, args.serial)
            result['stages'].append({'name': 'admin', 'passed': True})
        if args.stage in ('supervisor', 'all'):
            supervisor_stage(ui, state, args.serial)
            result['stages'].append({'name': 'supervisor_five_workers', 'passed': True})
        if args.stage in ('edit', 'all'):
            edit_stage(ui, state, args.serial)
            result['stages'].append({'name': 'edit_and_correction', 'passed': True})
        result['passed'] = True
        print('PASS: verificaciones de interfaz y persistencia completadas')
        return 0
    except Exception as error:
        result['passed'] = False
        result['error'] = str(error)
        try:
            ui.screenshot('failure')
        except Exception:
            pass
        traceback.print_exc()
        return 1
    finally:
        (artifacts / ('result_' + args.stage + '.json')).write_text(
            json.dumps(result, indent=2), encoding='utf-8'
        )
        print('Evidencia: ' + str(artifacts))


if __name__ == '__main__':
    sys.exit(run())
