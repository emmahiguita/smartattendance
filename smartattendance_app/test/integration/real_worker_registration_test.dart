// QUÉ HACE: Verifica altas y permisos con archivos SQLite reales temporales.
// CÓMO: Ejecuta los repositorios de producción con SQLite FFI, sin mocks.
// POR QUÉ: La cuenta, cuadrilla y personal deben sobrevivir o revertirse juntos.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:smartattendance/core/localstore/local_database_service.dart';
import 'package:smartattendance/features/auth/data/datasources/local_auth_datasource.dart';
import 'package:smartattendance/features/photo_attendance/data/photo_database.dart';
import 'package:smartattendance/features/photo_attendance/data/photo_repository.dart';
import 'package:smartattendance/features/photo_attendance/data/local_admin_store.dart';
import 'package:smartattendance/features/photo_attendance/domain/local_actor.dart';
import 'package:smartattendance/features/photo_attendance/domain/worker_site.dart';

void main() {
  late Directory directory;
  late PhotoDatabase photos;
  late LocalDatabaseService accounts;
  const admin = LocalActor('900000001', true, isStrictAdmin: true);
  const password = 'PruebaSegura9';
  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    directory = await Directory.systemTemp.createTemp('attendance-registration-');
    await databaseFactory.setDatabasesPath(directory.path);
    photos = PhotoDatabase();
    accounts = LocalDatabaseService();
    await accounts.database;
    await photos.database;
  });
  tearDown(() async {
    await (await photos.database).close();
    await (await accounts.database).close();
    await directory.delete(recursive: true);
  });
  Future<int> team(String doc) async => (await photos.database).insert('crews', {
    'name': 'Equipo QA $doc', 'supervisor_document': doc,
    'valid_from': '2026-01-01', 'valid_until': '2027-12-31'});

  test('administrador crea supervisor; supervisor registra y autentica cinco trabajadores', () async {
    final crew = await team('900000002');
    await PhotoRepository(photos, admin).addWorker('Supervisor QA', '900000002', 'Supervisor',
      password: password, crewId: crew);
    final login = await LocalAuthDataSource(accounts).loginByCedula('900000002', password: password);
    expect(login.$3.cargo, 'Supervisor');
    final supervisor = PhotoRepository(photos,
      const LocalActor('900000002', true, isSupervisor: true));
    for (var i = 1; i <= 5; i++) {
      await supervisor.addWorker('Trabajador QA $i', '90100000$i', 'Operario',
        password: '${password}x$i', crewId: crew);
    }
    final visible = await supervisor.workers();
    expect(visible.where((worker) => worker.job == 'Operario').length, 5);
    final worker = await LocalAuthDataSource(accounts).loginByCedula('901000005', password: '${password}x5');
    expect(worker.$3.cargo, 'Operario');
    await expectLater(LocalAuthDataSource(accounts).loginByCedula('901000005', password: 'incorrecta'), throwsFormatException);
    final stored = await accounts.getLocalUserByCedula('901000005');
    expect(stored!['password_hash'], startsWith('pbkdf2-sha256\$'));
    expect(stored['password_hash'], isNot('${password}x5'));
  }, timeout: const Timeout(Duration(minutes: 4)));

  test('duplicado de cuenta revierte trabajador y sitio sin alterar el equipo', () async {
    final crew = await team('900000002');
    await accounts.insertLocalUser({'cedula': '901000001', 'nombre': 'Existente',
      'apellido': 'Válido', 'cargo': 'Operario', 'is_admin': 0, 'password_hash': 'anterior'});
    await expectLater(PhotoRepository(photos, admin).addWorker('Duplicado', '901000001', 'Operario',
      password: password, crewId: crew, site: const WorkerSite(name: 'Sitio QA',
        address: 'Dirección QA', latitude: 4.81, longitude: -75.69)), throwsFormatException);
    final db = await photos.database;
    expect(await db.query('workers'), isEmpty);
    expect(await db.query('work_zones'), isEmpty);
    expect((await db.query('crews')).single['zone_id'], isNull);
    expect((await accounts.getLocalUserByCedula('901000001'))!['nombre'], 'Existente');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('supervisor no crea mandos ni trabajadores o sitios en equipo ajeno', () async {
    final mine = await team('900000002'), other = await team('900000003');
    final repository = PhotoRepository(photos,
      const LocalActor('900000002', true, isSupervisor: true));
    await expectLater(repository.addWorker('Mando', '901000002', 'Administrador',
      password: password, crewId: mine), throwsFormatException);
    await expectLater(repository.addWorker('Ajeno', '901000003', 'Operario',
      password: password, crewId: other, site: const WorkerSite(name: 'Ajeno',
        address: 'Sitio ajeno', latitude: 4.81, longitude: -75.69)), throwsFormatException);
    expect(await (await photos.database).query('workers'), isEmpty);
    expect(await (await accounts.database).query('usuarios_locales'), isEmpty);
    expect(await (await photos.database).query('work_zones'), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('supervisor no reasigna, elimina ni consulta personal de otro equipo', () async {
    final mine = await team('900000002'), other = await team('900000003');
    final db = await photos.database;
    final id = await db.insert('workers', {'name': 'Persona ajena', 'document': '901000003',
      'job': 'Operario', 'crew_id': other});
    await accounts.insertLocalUser({'cedula': '901000003', 'nombre': 'Persona',
      'apellido': 'ajena', 'cargo': 'Operario', 'is_admin': 0});
    final store = LocalAdminStore(photos, const LocalActor('900000002', true, isSupervisor: true));
    await expectLater(store.assignWorker(id, mine, null, 'Intento QA'), throwsFormatException);
    await expectLater(store.setWorkerCrew(id, mine), throwsFormatException);
    await expectLater(store.deleteWorker(id), throwsFormatException);
    await expectLater(store.workerConfig(id), throwsFormatException);
    expect((await db.query('workers')).single['crew_id'], other);
    expect(await accounts.getLocalUserByCedula('901000003'), isNotNull);
    expect((await store.rows('crews')).single['id'], mine);
  });

  test('administrador recupera cuenta local con contraseña individual; supervisor ajeno no puede', () async {
    final crew = await team('900000003');
    final id = await (await photos.database).insert('workers', {'name': 'Cuenta previa',
      'document': '901000003', 'job': 'Operario', 'crew_id': crew});
    await accounts.insertLocalUser({'cedula': '901000003', 'nombre': 'Cuenta', 'apellido': 'previa',
      'cargo': 'Operario', 'is_admin': 0, 'password_hash': '901000003'});
    await LocalAdminStore(photos, admin).setWorkerPassword(id, password);
    final login = await LocalAuthDataSource(accounts).loginByCedula('901000003', password: password);
    expect(login.$3.cedula, '901000003');
    final protected = await accounts.getLocalUserByCedula('901000003');
    final supervisor = LocalAdminStore(photos, const LocalActor('900000002', true, isSupervisor: true));
    await expectLater(supervisor.setWorkerPassword(id, 'OtraClave9'), throwsFormatException);
    expect((await accounts.getLocalUserByCedula('901000003'))!['password_hash'], protected!['password_hash']);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('administrador crea puestos; nuevo equipo guarda puestos, sitio con dirección y asigna Operador/Colaborador/Operario', () async {
    final adminStore = LocalAdminStore(photos, admin);
    final supStore = LocalAdminStore(photos, const LocalActor('900000002', true, isSupervisor: true));

    // El Administrador crea un puesto nuevo; el Supervisor no puede crear puestos globales.
    final custom = await adminStore.addCustomJobPosition('Operador de Planta');
    expect(custom, contains('Operador de Planta'));
    await expectLater(supStore.addCustomJobPosition('Puesto No Autorizado'), throwsFormatException);

    // Crear Sitio de trabajo con dirección física y Nuevo Equipo vinculado a ese sitio.
    final zoneId = await adminStore.saveZone({
      'name': 'Planta Acueducto Dosquebradas',
      'address': 'Calle 25 # 20-30, Dosquebradas',
      'latitude': 4.8333,
      'longitude': -75.6833,
      'radius_m': 150.0,
    });
    final crewId = await adminStore.saveCrew({
      'name': 'Cuadrilla Redes Norte',
      'supervisor_document': '900000002',
      'driver_document': '',
      'zone_id': zoneId,
      'valid_from': '2026-01-01',
      'valid_until': '2027-12-31',
    });
    await adminStore.saveCrewPositions(crewId, ['Operador', 'Colaborador', 'Operario', 'Operador de Planta']);
    expect(await adminStore.crewPositions(crewId), containsAll(['Operador', 'Colaborador', 'Operario', 'Operador de Planta']));

    final crewsWithZone = await adminStore.crewsWithZones();
    final createdCrew = crewsWithZone.firstWhere((c) => c['id'] == crewId);
    expect(createdCrew['zone_name'], 'Planta Acueducto Dosquebradas');
    expect(createdCrew['zone_address'], 'Calle 25 # 20-30, Dosquebradas');

    // Registrar y asignar personal con puestos Operador, Colaborador y Operario.
    final repo = PhotoRepository(photos, admin);
    await repo.addWorker('Luis Operador', '902000001', 'Colaborador', password: password);
    final workers = await repo.workers();
    final luis = workers.firstWhere((w) => w.document == '902000001');
    await adminStore.setWorkerCrew(luis.id, crewId, role: 'Operador');

    final updatedLuis = (await repo.workers()).firstWhere((w) => w.id == luis.id);
    expect(updatedLuis.crewId, crewId);
    expect(updatedLuis.job, 'Operador');
    expect(updatedLuis.zoneName, 'Planta Acueducto Dosquebradas');
    expect((await accounts.getLocalUserByCedula('902000001'))!['cargo'], 'Operador');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
