"""Consulta OSV sobre versiones declaradas sin enviar secretos ni código."""
import json
import re
import urllib.request
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]
packages = []
for line in (ROOT/'smartattendance_backend/requirements.txt').read_text().splitlines():
    match = re.match(r'([\w-]+)(?:\[[^]]+\])?==([\w.]+)', line)
    if match:
        packages.append(('PyPI', *match.groups()))
lock = yaml.safe_load((ROOT/'smartattendance_app/pubspec.lock').read_text())
for name, data in lock['packages'].items():
    if data.get('source') == 'hosted':
        packages.append(('Pub', name, data['version']))
queries = [{'package': {'ecosystem': eco, 'name': name}, 'version': version}
           for eco, name, version in packages]
request = urllib.request.Request('https://api.osv.dev/v1/querybatch',
    data=json.dumps({'queries': queries}).encode(),
    headers={'Content-Type': 'application/json'})
with urllib.request.urlopen(request, timeout=60) as response:
    results = json.load(response)['results']
findings = []
for package, result in zip(packages, results):
    if result.get('vulns'):
        findings.append({'ecosystem': package[0], 'package': package[1],
                         'version': package[2], 'ids': [v['id'] for v in result['vulns']]})
report = {'packages_queried': len(packages), 'findings': findings,
          'limitation': 'Backend: versiones exactas declaradas; no cubre rangos sin lock ni SDK nativo.'}
(ROOT/'qa/dependency_audit.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
