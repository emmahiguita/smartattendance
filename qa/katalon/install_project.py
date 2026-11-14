"""Instala casos nuevos sin sustituir los casos propios del usuario."""
import os
import shutil
import sys
import uuid
import xml.etree.ElementTree as ET
from pathlib import Path

root = Path(__file__).resolve().parents[2]
project = Path(os.getenv('SA_KATALON_PROJECT', str(Path.home()/'Katalon Studio/Buenos dias')))
assert list(project.glob('*.prj')), 'No es un proyecto Katalon'
keywords = project/'Keywords/com/smartattendance/testing'
keywords.mkdir(parents=True, exist_ok=True)
shutil.copy2(root/'qa/katalon/AndroidAutomation.groovy', keywords/'AndroidAutomation.groovy')
(project/'automation.properties').write_text('projectRoot='+root.as_posix()+'\npython='+Path(sys.executable).as_posix()+'\n', encoding='utf-8')

def case(name, stage):
    path = 'Android Automatico/'+name
    entity = ET.Element('TestCaseEntity')
    for key, value in [('description','Prueba real Android: '+stage),('name',name),('testCaseGuid',str(uuid.uuid5(uuid.NAMESPACE_URL,path)))]:
        ET.SubElement(entity,key).text = value
    target = project/'Test Cases'/ (path+'.tc')
    target.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(entity).write(target, encoding='utf-8', xml_declaration=True)
    scripts = project/'Scripts'/path
    scripts.mkdir(parents=True, exist_ok=True)
    method = {'preflight':'detectarAndroid', 'smoke':'comprobarPantalla',
              'admin':'probarAdministrador', 'supervisor':'probarSupervisor'}[stage]
    (scripts/'Script1794268800000.groovy').write_text(
        "import com.smartattendance.testing.AndroidAutomation as QA\nQA."+method+"()\n", encoding='utf-8')
    return 'Test Cases/'+path

cases = {stage:case(name,stage) for name,stage in [
    ('00_Detectar_Android','preflight'),('01_Navegacion','smoke'),
    ('02_Administrador','admin'),('03_Supervisor_Cinco_Trabajadores','supervisor')]}
for name, stages in [('TS_Android_Automatico',['preflight','smoke']),
                     ('TS_Android_Administrativo',['preflight','admin','supervisor'])]:
    suite = ET.Element('TestSuiteEntity')
    for key,value in [('name',name),('testSuiteGuid',str(uuid.uuid5(uuid.NAMESPACE_URL,name))),('isRerun','false'),('numberOfRerun','0')]:
        ET.SubElement(suite,key).text = value
    for stage in stages:
        link = ET.SubElement(suite,'testCaseLink')
        for key,value in [('guid',str(uuid.uuid5(uuid.NAMESPACE_URL,name+stage))),('isReuseDriver','false'),('isRun','true'),('testCaseId',cases[stage]),('usingDataBindingAtTestSuiteLevel','true')]:
            ET.SubElement(link,key).text = value
    ET.ElementTree(suite).write(project/'Test Suites'/(name+'.ts'), encoding='utf-8', xml_declaration=True)
print('Casos y suites instalados en '+str(project))
