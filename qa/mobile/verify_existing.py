"""Verifica en lectura los registros de la última ejecución y su sesión móvil."""
import json
import os
from pathlib import Path
from device import Device
from persistence import worker, rows, PACKAGE

folder = Path(os.environ['LOCALAPPDATA']) / 'SmartAttendanceQA'
state = json.loads((folder/'private_run_state.json').read_text(encoding='utf-8'))
serial = os.getenv('SA_DEVICE_SERIAL', 'VGL7MVFMDYQG8T55')
artifacts = folder / ('verification_' + state['run'])
ui = Device(serial, artifacts)
crew_ids = set()
for i, document in enumerate(state['workers']):
    person, account = worker(serial, document)
    assert person['supervisor_document'] == state['supervisor']
    assert not account['is_admin']
    assert person['zone_id'] is not None
    schedule = json.loads(person['schedule_json'])
    delta = 0 if i % 2 == 0 else 30
    assert schedule['markStart'] == (schedule['start'] - delta) % 1440
    assert schedule['markEnd'] == (schedule['end'] + delta) % 1440
    crew_ids.add(person['crew_id'])
assert len(crew_ids) == 1, 'Los cinco trabajadores no pertenecen al mismo equipo'
ui.d.app_stop(PACKAGE)
ui.d.app_start(PACKAGE)
ui.expect('Perfil', seconds=30)
ui.tap('Perfil', exact=True)
ui.expect(state['name'])
ui.screenshot('session_persisted')
report = {'passed': True, 'run': state['run'], 'workers_verified': 5,
          'checks': ['both_databases', 'same_team', 'roles', 'fixed_flexible_windows',
                     'worksite_persisted', 'session_after_restart'],
          'scope': 'Existing records verified; does not rerun all creation actions.'}
(artifacts/'result.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
