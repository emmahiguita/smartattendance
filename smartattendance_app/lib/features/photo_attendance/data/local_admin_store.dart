// ============================================================================
// ARCHIVO: local_admin_store.dart
// QUÉ HACE: Fachada administrativa para geocercas GPS (`work_zones`), equipos
//           (`crews`), asignaciones de personal/roles y baja de usuarios.
// CÓMO FUNCIONA:
// - Exige `requireAdmin()` en toda mutación.
// - Sincroniza altas, cambios de rol (`Colaborador`, `Supervisor`, `Administrador`)
//   y eliminaciones (`deleteWorker`) tanto en `PhotoDatabase.workers` como en
//   `LocalDatabaseService.usuarios_locales`, para que los cambios de login y
//   bajas tengan efecto inmediato.
// POR QUÉ: Garantiza que supervisores, administradores y trabajadores agregados
//          puedan iniciar sesión y que al borrarlos pierdan el acceso (< 190 líneas).
// ============================================================================

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/localstore/local_database_service.dart';
import '../../auth/data/datasources/local_auth_datasource.dart';
import '../domain/photo_record.dart';
import '../domain/shift_template.dart';
import '../domain/work_schedule.dart';
import 'journey_review_store.dart';
import 'local_shift_store.dart';
import 'photo_database.dart';

class LocalAdminStore {
  LocalAdminStore(this.database, this.adminDocument);
  final PhotoDatabase database;
  final String? adminDocument;

  late final LocalShiftStore _shiftStore = LocalShiftStore(
    database: database,
    requireAdmin: requireAdmin,
    ensureDefaultData: ensureDefaultData,
    getSetting: setting,
  );

  void requireAdmin() {
    if (adminDocument == null || adminDocument!.trim().isEmpty) {
      throw const FormatException('Acción exclusiva del administrador o supervisor.');
    }
  }

  Future<String?> setting(String name) async {
    final rows = await (await database.database).query('local_settings', where: 'name=?', whereArgs: [name]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> saveSetting(String name, String value) async {
    requireAdmin();
    await (await database.database).insert('local_settings', {'name': name, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> rows(String table) async {
    if (!const ['crews', 'work_zones'].contains(table)) throw ArgumentError('Tabla no permitida');
    await ensureDefaultData();
    return (await database.database).query(table, orderBy: 'name');
  }

  Future<List<Map<String, Object?>>> crewsWithZones() async {
    await ensureDefaultData();
    return (await database.database).rawQuery('''
      SELECT c.*, z.name as zone_name, z.address as zone_address, z.radius_m as zone_radius
      FROM crews c LEFT JOIN work_zones z ON c.zone_id = z.id ORDER BY c.name''');
  }

  Future<int> saveZone(Map<String, Object?> zone, {int? id}) async {
    requireAdmin();
    final lat = (zone['latitude'] as num).toDouble(), lng = (zone['longitude'] as num).toDouble(), rad = (zone['radius_m'] as num).toDouble();
    if ((zone['name'] as String).trim().isEmpty || !lat.isFinite || lat.abs() > 90 || !lng.isFinite || lng.abs() > 180 || !rad.isFinite || rad < 20 || rad > 50000) {
      throw const FormatException('Revisa nombre, coordenadas y radio (20 a 50000 metros).');
    }
    final db = await database.database;
    return id == null ? await db.insert('work_zones', zone) : (await db.update('work_zones', zone, where: 'id=?', whereArgs: [id]), id).$2;
  }

  Future<void> saveCrew(Map<String, Object?> crew, {int? id}) async {
    requireAdmin();
    final from = DateTime.tryParse(crew['valid_from'] as String), until = DateTime.tryParse(crew['valid_until'] as String);
    if ((crew['name'] as String).trim().isEmpty || from == null || until == null || until.isBefore(from) || !RegExp(r'^\d{3,20}$').hasMatch(crew['supervisor_document'] as String)) {
      throw const FormatException('Revisa nombre, cédula del supervisor y período.');
    }
    final driver = crew['driver_document'] as String?;
    if (driver != null && driver.isNotEmpty && !RegExp(r'^\d{3,20}$').hasMatch(driver)) {
      throw const FormatException('Identificación adicional inválida.');
    }
    final db = await database.database;
    id == null ? await db.insert('crews', crew) : await db.update('crews', crew, where: 'id=?', whereArgs: [id]);
    await db.rawUpdate(
      "UPDATE workers SET job = 'Supervisor' WHERE document = ? AND LOWER(job) = 'colaborador'",
      [(crew['supervisor_document'] as String).trim()],
    );
  }

  /// QUÉ HACE: Asigna cuadrilla, horario y rol (Colaborador/Supervisor/Administrador) y sincroniza login.
  Future<void> assignWorker(int workerId, int? crewId, WorkSchedule? schedule, String authorizationReference, {String? role}) async {
    requireAdmin();
    await ensureDefaultData();
    final privacy = await setting('privacy') ?? 'Política General SmartAttendance';
    final authRef = authorizationReference.trim().isNotEmpty ? authorizationReference.trim() : 'Asignación administrativa';
    if (schedule != null && (schedule.dailyMinutes <= 0 || schedule.dailyMinutes > 1440 || schedule.nightStartMinute == schedule.nightEndMinute)) {
      throw const FormatException('Duración de jornada inválida.');
    }
    final db = await database.database;
    if (crewId != null && (await db.query('crews', where: 'id=?', whereArgs: [crewId])).isEmpty) {
      throw const FormatException('Selecciona un equipo existente.');
    }
    final cleanRole = (role != null && role.trim().isNotEmpty) ? role.trim() : null;
    await db.update('workers', {
      'crew_id': crewId,
      'schedule_json': schedule?.encode(),
      if (cleanRole != null) 'job': cleanRole,
      'authorization_reference': authRef,
      'authorization_policy': privacy,
      'authorization_at': DateTime.now().toUtc().toIso8601String(),
    }, where: 'id=?', whereArgs: [workerId]);

    if (cleanRole != null) {
      final wRows = await db.query('workers', where: 'id=?', whereArgs: [workerId], limit: 1);
      if (wRows.isNotEmpty) {
        final doc = (wRows.first['document'] as String).trim();
        final authDb = await LocalDatabaseService().database;
        await authDb.update('usuarios_locales', {'cargo': cleanRole, 'is_admin': LocalAuthDataSource.isRoleAdmin(cleanRole, doc) ? 1 : 0}, where: 'cedula=?', whereArgs: [doc]);
      }
    }
  }

  Future<Map<String, Object?>> workerConfig(int id) async {
    requireAdmin();
    final rows = await (await database.database).query('workers', where: 'id=?', whereArgs: [id]);
    if (rows.isEmpty) throw const FormatException('Trabajador no encontrado.');
    return rows.first;
  }

  Future<void> applySchedule(PhotoDay day) { requireAdmin(); return JourneyReviewStore(database, adminDocument!).applySchedule(day); }
  Future<void> review(PhotoDay day, {required bool approve, bool abandon = false}) { requireAdmin(); return JourneyReviewStore(database, adminDocument!).review(day, approve: approve, abandon: abandon); }

  Future<void> savePrivacy(Map<String, String> fields) async {
    requireAdmin();
    if (fields.values.any((v) => v.trim().isEmpty) || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(fields['email'] ?? '')) {
      throw const FormatException('Completa responsable, contacto, finalidad y conservación.');
    }
    await saveSetting('privacy', jsonEncode(fields));
  }

  Future<void> ensureDefaultData() async {
    final db = await database.database;
    final p = await setting('privacy');
    if (p == null || !p.contains('"company"')) {
      await db.insert('local_settings', {
        'name': 'privacy',
        'value': jsonEncode({'company': 'Talento Humano & Operaciones', 'responsible': 'Talento Humano & Operaciones', 'email': 'rrhh@smartattendance.local', 'phone': '+57 300 000 0000', 'purpose': 'Control de asistencia biométrica, geocerca GPS y gestión horaria', 'retention': '5 años conforme a normativa laboral vigente'}),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await LocalShiftStore.seedDefaultShifts(db);
    await db.transaction((tx) async {
      await tx.rawDelete('DELETE FROM crews WHERE id NOT IN (SELECT MIN(id) FROM crews GROUP BY name)');
      await tx.rawDelete('DELETE FROM work_zones WHERE id NOT IN (SELECT MIN(id) FROM work_zones GROUP BY name)');
      if ((Sqflite.firstIntValue(await tx.rawQuery('SELECT COUNT(*) FROM work_zones')) ?? 0) == 0) {
        final zoneId = await tx.insert('work_zones', {'name': 'Sede Principal Operativa', 'address': 'Calle 25 # 20-30, Dosquebradas, Risaralda', 'latitude': 6.2874, 'longitude': -75.5871, 'radius_m': 250.0});
        await tx.insert('crews', {'name': 'Equipo Operativo Central', 'supervisor_document': adminDocument ?? '1007331963', 'zone_id': zoneId, 'valid_from': '2026-01-01', 'valid_until': '2026-12-31'});
      }
    });
  }

  Future<void> deleteZone(int id) async {
    requireAdmin();
    final db = await database.database;
    if ((await db.query('crews', where: 'zone_id=?', whereArgs: [id])).isNotEmpty) {
      throw const FormatException('No se puede eliminar la geocerca: tiene cuadrillas asignadas.');
    }
    await db.delete('work_zones', where: 'id=?', whereArgs: [id]);
  }

  Future<void> deleteCrew(int id) async {
    requireAdmin();
    final db = await database.database;
    await db.update('workers', {'crew_id': null}, where: 'crew_id=?', whereArgs: [id]);
    await db.delete('crews', where: 'id=?', whereArgs: [id]);
  }

  /// QUÉ HACE: Elimina un Colaborador, Supervisor o Administrador y revoca su acceso al login.
  Future<void> deleteWorker(int id) async {
    requireAdmin();
    final db = await database.database;
    final rows = await db.query('workers', where: 'id=?', whereArgs: [id], limit: 1);
    if (rows.isNotEmpty) {
      final doc = (rows.first['document'] as String? ?? '').trim();
      if (doc == '1007331963') {
        throw const FormatException('No se puede eliminar al Administrador Principal del sistema.');
      }
      final authDb = await LocalDatabaseService().database;
      await authDb.delete('usuarios_locales', where: 'cedula=?', whereArgs: [doc]);
      await authDb.delete('empleados_cache', where: 'cedula=?', whereArgs: [doc]);
    }
    await db.delete('workers', where: 'id=?', whereArgs: [id]);
  }

  Future<List<ShiftTemplate>> shiftTemplates() => _shiftStore.shiftTemplates();
  Future<void> saveShiftTemplate(ShiftTemplate t) => _shiftStore.saveShiftTemplate(t);
  Future<void> deleteShiftTemplate(int id) => _shiftStore.deleteShiftTemplate(id);
  Future<void> assignShiftToWorkers({required List<int> workerIds, required ShiftTemplate template, String? reference}) => _shiftStore.assignShiftToWorkers(workerIds: workerIds, template: template, reference: reference);
  Future<void> removeScheduleFromWorker(int workerId) => _shiftStore.removeScheduleFromWorker(workerId);
  Future<List<PhotoDay>> allOvertimeDays() => _shiftStore.allOvertimeDays();
}
