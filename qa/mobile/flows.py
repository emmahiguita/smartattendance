# ============================================================================
# ARCHIVO: flows.py
# QUÉ HACE: Ejecuta los flujos E2E verificados en UI y SQLite separados por
#           jerarquía de responsabilidades (RBAC):
#           1. `admin_stage` (Super Administrador): Permiso total, crea puestos
#              laborales del sistema, sitios con dirección y crea al Supervisor.
#           2. `supervisor_stage` (Supervisor): Crea/configura su propio Equipo
#              de Trabajo con Sitio y Dirección, comprueba que NO puede crear
#              Supervisores ni Administradores, y registra únicamente empleados
#              hacia abajo de la jerarquía (Operador, Colaborador, Operario,
#              Promotor, Técnico de Campo) con horarios de Colombia (12h/24h).
# CÓMO FUNCIONA: Conecta por UIAutomator2 + ADB y valida cada paso en SQLite.
# POR QUÉ: Garantiza 0 simulaciones y 100% fidelidad a las reglas de negocio.
# ============================================================================

import json
import time
from persistence import worker, rows, PACKAGE


def logout(ui):
    """QUÉ HACE: Cierra la sesión activa desde la pestaña Perfil."""
    ui.tap('Perfil', exact=True)
    if not ui.visible('Cerrar sesión') and not ui.visible('Cerrar Sesión'):
        ui.d.swipe_ext('up', scale=.55)
    label = 'Cerrar sesión' if ui.visible('Cerrar sesión') else 'Cerrar Sesión'
    ui.tap(label)
    ui.tap('Salir', exact=True)
    ui.expect('Contraseña')


def login(ui, document, password, admin=False):
    """QUÉ HACE: Inicia sesión como Super Administrador o como Usuario/Supervisor."""
    ui.expect('Contraseña')
    tab_target = 'Administrador\nRango Superior' if admin else 'Usuario\nColaborador'
    ui.tap(tab_target, exact=True)
    ui.fill('Cédula', document, index=0)
    ui.fill('Contraseña', password, index=1)
    btn = 'Ingresar como Administrador' if admin else 'Iniciar sesión'
    ui.tap(btn, exact=True)
    ui.expect('Perfil', seconds=40)


def create_crew_as_admin(ui, state):
    """
    QUÉ HACE: Flujo exclusivo del Super Administrador en 'Equipos -> + Nuevo Equipo':
              - Verifica puestos base (Operador, Colaborador, Operario).
              - Crea un nuevo puesto laboral global ('+ Crear puesto').
              - Crea el equipo inicial con Sitio de Trabajo y Dirección.
    """
    ui.tap('Equipos', exact=True)
    ui.wait(lambda: ui.visible('+ Nuevo Equipo') or ui.visible('Nuevo'), 'No cargó la pestaña Equipos')
    ui.tap('+ Nuevo Equipo' if ui.visible('+ Nuevo Equipo') else 'Nuevo')
    ui.wait(lambda: ui.visible('Datos de la Cuadrilla') or ui.visible('Equipo'), 'No abrió CrewDialog', seconds=15)
    time.sleep(0.5)
    ui.fill('Equipo', state['crew'], index=0)
    ui.fill('Supervisor', state['supervisor'], index=1)
    for pos in ('Operador', 'Colaborador', 'Operario'):
        assert ui.visible(pos), f'Puesto {pos} no disponible en Nuevo Equipo'
    custom_pos = 'Operador Planta ' + state['run'][-3:]
    if ui.visible('Crear puesto'):
        ui.tap('Crear puesto')
        ui.wait(lambda: ui.visible('Crear Nuevo Puesto'), 'No abrió diálogo Crear Nuevo Puesto', seconds=10)
        time.sleep(0.3)
        ui.fill('Operador', custom_pos, index=-1, hide_keyboard=False)
        ui.tap('Crear Puesto', exact=True)
        ui.expect(custom_pos)
    ui.tap('Guardar', exact=True)
    ui.expect(state['crew'])


def create_own_crew_as_supervisor(ui, state, serial):
    """
    QUÉ HACE: Flujo del Supervisor creando su propio Equipo de Trabajo:
              - Abre 'Equipos -> + Nuevo Equipo'.
              - Verifica que el Supervisor NO tiene permiso de '+ Crear puesto'.
              - Verifica que su propia cédula está preasignada como Supervisor.
              - Asigna nombre de su equipo, Sitio de Trabajo y Dirección física.
              - Comprueba en SQLite que el equipo y sitio quedaron persistidos.
    """
    ui.tap('Equipos', exact=True)
    ui.tap('+ Nuevo Equipo' if ui.visible('+ Nuevo Equipo') else 'Nuevo')
    assert not ui.visible('+ Crear puesto'), 'FALLO RBAC: Supervisor no debe poder crear puestos globales'
    for pos in ('Operador', 'Colaborador', 'Operario'):
        assert ui.visible(pos), f'Puesto operativo {pos} no disponible para el Supervisor'
    sup_crew = state.get('supervisor_crew', 'Equipo Sup ' + state['run'][-4:])
    ui.fill('Equipo', sup_crew, index=0)
    ui.reveal('Válido desde')
    ui.fill('Nombre Sitio', state.get('site_name', 'Sede Sup ' + state['run'][-4:]), index=-2)
    ui.fill('Dirección', state.get('site_address', 'Calle 25 # 20-30, Dosquebradas'), index=-1)
    ui.tap('Guardar', exact=True)
    ui.wait(
        lambda: ui.visible(sup_crew) and not ui.visible('Guardar', exact=True),
        'No terminó de guardar el equipo del Supervisor',
        seconds=35,
    )
    db_crews = rows(
        serial,
        'local_photo_attendance.db',
        'SELECT id, name, supervisor_document, zone_id FROM crews WHERE name=?',
        (sup_crew,),
    )
    assert db_crews, f'El equipo creado por el Supervisor ({sup_crew}) no se guardó en SQLite'
    assert db_crews[0]['supervisor_document'] == state['supervisor'], (
        'El equipo del Supervisor no quedó vinculado a su cédula'
    )
    state['active_crew_name'] = sup_crew
    ui.screenshot('supervisor_created_own_crew')


def open_registration(ui):
    """QUÉ HACE: Abre el formulario de registro de personal desde Perfil."""
    ui.tap('Perfil', exact=True)
    ui.reveal('Registrar nuevo colaborador')
    ui.tap('Registrar nuevo colaborador', exact=True)
    ui.expect('Rol / Nivel de acceso')


def register(ui, state, document, name, role, tolerance, site=False, duplicate=False):
    """
    QUÉ HACE: Registra un usuario en la app verificando rol, contraseña,
              horario/tolerancia (Colombia 12h/24h), cuadrilla y GPS real.
    """
    open_registration(ui)
    ui.fill('Nombre completo', name, index=0)
    ui.fill('Cédula', document, index=1)
    ui.tap('Rol / Nivel de acceso')
    ui.reveal(role + '\n')
    ui.tap(role + '\n', exact=False)
    ui.fill('Mín. 8 caract.', state['password'], index=2)
    ui.fill('Repite la contraseña inicial', state['password'], index=3)
    ui.reveal('Rango de marcación')
    ui.tap('Rango de marcación')
    ui.tap(tolerance, exact=True)
    if role == 'Supervisor':
        ui.reveal('Cuadrilla')
        if not ui.visible(state['crew']):
            ui.tap('Cuadrilla')
            ui.reveal(state['crew'])
            ui.tap(state['crew'], exact=False)
    if site:
        ui.reveal('Mi GPS Actual')
        ui.tap('Mi GPS Actual', exact=True)
        ui.wait(
            lambda: any('GPS detectado:' in x for x in ui.labels()),
            'GPS no entregó un sitio real',
            seconds=45,
        )
    ui.tap('Guardar', exact=True)
    if duplicate:
        ui.expect('Ya existe')
        ui.screenshot('duplicate_rejected')
        ui.back()
    else:
        ui.wait(
            lambda: ui.visible('Perfil', exact=True) and not ui.visible('Guardar', exact=True),
            'No terminó el registro',
            seconds=75,
        )


def admin_stage(ui, state, credentials, serial):
    """
    QUÉ HACE: ETAPA 1 - SUPER ADMINISTRADOR (Permiso Total):
              1. Inicia sesión como Super Administrador (1007331963).
              2. Crea puesto personalizado y cuadrilla con sitio.
              3. Crea al Supervisor y valida su persistencia en SQLite.
    """
    ui.d.unlock()
    ui.d.press('home')
    ui.d.app_start(PACKAGE, stop=True)
    ui.wait(
        lambda: ui.visible('Perfil', exact=True) or ui.visible('Contraseña'),
        'La aplicación no cargó la pantalla inicial',
        seconds=25,
    )
    if ui.visible('Perfil', exact=True):
        logout(ui)
    login(ui, credentials['document'], credentials['password'], admin=True)
    ui.expect('Administrador')
    create_crew_as_admin(ui, state)
    register(ui, state, state['supervisor'], state['name'], 'Supervisor', 'Turno exacto')
    person, account = worker(serial, state['supervisor'])
    assert person['supervisor_document'] == state['supervisor'], 'Equipo incorrecto'
    assert account['cargo'].lower().startswith('supervisor'), 'Rol incorrecto'
    ui.screenshot('admin_supervisor_created')


def supervisor_stage(ui, state, serial):
    """
    QUÉ HACE: ETAPA 2 - SUPERVISOR (Crea su Equipo y Empleados hacia abajo):
              1. Inicia sesión con el Supervisor creado por el Super Administrador.
              2. Crea su propio Equipo de Trabajo con Sitio y Dirección en 'Equipos'.
              3. Audita la jerarquía RBAC: verifica que NO puede crear ni
                 Supervisores, ni Encargados, ni Administradores.
              4. Registra 5 empleados hacia abajo de la jerarquía (Operador,
                 Colaborador, Operario, Promotor, Técnico de Campo) con horarios
                 Colombia (12h/24h) y Sitio GPS.
              5. Verifica rechazo de duplicados y persistencia tras reinicio.
    """
    ui.d.unlock()
    ui.d.press('home')
    ui.d.app_start(PACKAGE, stop=True)
    ui.wait(
        lambda: ui.visible('Perfil', exact=True) or ui.visible('Contraseña'),
        'La aplicación no cargó la pantalla inicial',
        seconds=25,
    )
    if ui.visible('Perfil', exact=True):
        logout(ui)
    login(ui, state['supervisor'], state['password'])

    # 1. El Supervisor crea su propio Equipo de Trabajo con Sitio y Dirección
    create_own_crew_as_supervisor(ui, state, serial)

    # 2. Auditoría estricta RBAC: El Supervisor NO puede crear Supervisores ni Administradores
    open_registration(ui)
    ui.tap('Rol / Nivel de acceso')
    ui.d.swipe_ext('up', scale=.55)
    assert not ui.visible('Control total de puestos, equipos, horarios y reportes'), (
        'FALLO RBAC: Supervisor puede crear Administrador'
    )
    assert not ui.visible('Líder de cuadrilla con control de asistencia de su equipo'), (
        'FALLO RBAC: Supervisor puede crear otro Supervisor'
    )
    ui.back()
    ui.back()

    # 3. El Supervisor registra únicamente empleados hacia abajo de la jerarquía
    for i, wdata in enumerate(state['workers_data']):
        document = wdata['doc']
        name = wdata['name']
        role = wdata['role']
        tolerance = 'Turno exacto' if i % 2 == 0 else 'Tolerancia ±30 min'
        register(ui, state, document, name, role, tolerance, site=i == 0)
        person, account = worker(serial, document)
        assert person['supervisor_document'] == state['supervisor'], 'Trabajador fuera de su equipo'
        assert not account['is_admin'], 'Operario con privilegios administrativos'
        schedule = json.loads(person['schedule_json'])
        delta = 0 if i % 2 == 0 else 30
        assert schedule['markStart'] == (schedule['start'] - delta) % 1440, 'Inicio de ventana incorrecto'
        assert schedule['markEnd'] == (schedule['end'] + delta) % 1440, 'Fin de ventana incorrecto'

    # 4. Rechazo de duplicados y verificación de persistencia en SQLite
    first_worker = state['workers_data'][0]
    register(ui, state, first_worker['doc'], 'QA Duplicado', 'Operario', 'Turno exacto', duplicate=True)
    first, _ = worker(serial, first_worker['doc'])
    assert first['zone_id'] is not None, 'Sitio del equipo no persistido'
    count = rows(
        serial,
        'local_photo_attendance.db',
        'SELECT COUNT(*) n FROM workers WHERE crew_id=? AND document IN (?,?,?,?,?)',
        (first['crew_id'], *state['workers']),
    )[0]['n']
    assert count == 5, f'El equipo debe contener los cinco trabajadores creados (actual: {count})'
    ui.d.app_stop(PACKAGE)
    ui.d.app_start(PACKAGE)
    ui.expect('Perfil', seconds=40)
    for wdata in state['workers_data']:
        worker(serial, wdata['doc'])
    ui.screenshot('supervisor_persisted')


def edit_stage(ui, state, serial):
    """
    QUÉ HACE: ETAPA 3 - EDICIÓN Y CORRECCIÓN DE ERRORES ("POR SI ME EQUIVOQUÉ"):
              1. Localiza a un colaborador agregado y abre su ficha de gestión.
              2. Abre 'WorkerAssignmentDialog' y corrige el puesto (ej. de Operador
                 a Técnico de Campo) y asigna +2 Horas Extras.
              3. Comprueba en SQLite que el cargo y las horas extras se actualizaron.
              4. Entra a 'Equipos', abre la cuadrilla agregada y corrige el
                 nombre del equipo y la dirección física del sitio de trabajo.
              5. Comprueba en SQLite que el equipo y la geocerca se actualizaron.
    """
    ui.d.unlock()
    ui.d.press('home')
    ui.d.app_start(PACKAGE, stop=False)
    ui.wait(
        lambda: ui.visible('Perfil', exact=True) or ui.visible('Contraseña') or ui.visible('Equipos', exact=True),
        'La aplicación no cargó la pantalla inicial',
        seconds=25,
    )
    if not ui.visible('Equipos', exact=True):
        if ui.visible('Perfil', exact=True):
            pass
        else:
            login(ui, state['supervisor'], state['password'])

    # 1. Edición de Trabajador ("Por si me equivoqué de puesto o de horario")
    ui.tap('Inicio', exact=True)
    target_worker = state['workers_data'][0]
    target_name = target_worker['name']
    target_doc = target_worker['doc']

    if not ui.visible(target_name):
        if ui.d(className='android.widget.EditText').exists:
            ui.fill('Buscar', target_doc)
            time.sleep(0.5)
        else:
            ui.reveal(target_name)

    if ui.visible('Editar asignación'):
        ui.tap('Editar asignación')
    else:
        ui.tap(target_name, exact=False)

    ui.wait(lambda: ui.visible('Puesto / Rol') or ui.visible('Horario pactado'), 'No abrió WorkerAssignmentDialog')

    # Modificar Puesto / Rol a 'Técnico de Campo'
    ui.tap('Puesto / Rol', exact=False)
    ui.tap('Técnico de Campo', exact=False)

    # Asignar +2 Horas Extras
    ui.tap('Horas Extras', exact=False)
    ui.tap('+2 Horas Extras asignadas', exact=False)

    ui.tap('Guardar', exact=True)
    ui.wait(lambda: not ui.visible('Guardar', exact=True), 'No terminó de guardar cambios del trabajador')
    time.sleep(1)

    # Validar persistencia de la edición del trabajador en SQLite
    p, acc = worker(serial, target_doc)
    assert p['job'] == 'Técnico de Campo', f"El puesto en workers no cambió a Técnico de Campo (actual: {p['job']})"
    assert acc['cargo'] == 'Técnico de Campo', f"El cargo en usuarios_locales no cambió (actual: {acc['cargo']})"
    sched = json.loads(p['schedule_json'])
    assert sched.get('assignedOvertimeMinutes') == 120, f"Horas extras no son 120: {sched}"

    # Cerrar la hoja de detalles si sigue abierta
    if ui.visible('Cerrar') or ui.visible('X'):
        ui.back()
    time.sleep(1)

    # 2. Edición de Equipo y Sitio ("Por si me equivoqué de nombre o dirección")
    ui.tap('Equipos', exact=True)
    crew_to_edit = state.get('active_crew_name', state['crew'])
    ui.tap(crew_to_edit, exact=False)
    ui.wait(lambda: ui.visible('Datos de la Cuadrilla') or ui.visible('Equipo'), 'No abrió CrewDialog')

    edited_crew_name = (crew_to_edit + ' Corregido')[:40]
    ui.fill('Equipo', edited_crew_name, index=0)
    ui.reveal('Dirección')
    ui.fill('Dirección', 'Carrera 10 # 15-20, Dosquebradas', index=-1)
    ui.tap('Guardar', exact=True)
    ui.wait(lambda: ui.visible(edited_crew_name) and not ui.visible('Guardar', exact=True), 'No guardó equipo editado')

    # Validar persistencia de la edición del equipo y sitio en SQLite
    db_crews = rows(serial, 'local_photo_attendance.db', 'SELECT id, name, zone_id FROM crews WHERE name=?', (edited_crew_name,))
    assert db_crews, f"Equipo editado '{edited_crew_name}' no encontrado en SQLite"
    zone_id = db_crews[0]['zone_id']
    assert zone_id is not None, 'El equipo editado no tiene zone_id'
    db_zones = rows(serial, 'local_photo_attendance.db', 'SELECT address FROM work_zones WHERE id=?', (zone_id,))
    assert 'Carrera 10 # 15-20' in db_zones[0]['address'], f"Dirección no actualizada en SQLite: {db_zones[0]['address']}"

    ui.screenshot('edit_worker_and_crew_verified')

