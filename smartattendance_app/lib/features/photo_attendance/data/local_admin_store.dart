// ============================================================================
// ARCHIVO: local_admin_store.dart
// QUÉ HACE: Fachada administrativa para geocercas GPS (`work_zones`), equipos
//           (`crews`), puestos laborales (`custom_job_positions`), asignaciones
//           de personal/roles y baja de usuarios.
// CÓMO FUNCIONA:
// - Exige `requireAdmin()` o `requireManagement()` según jerarquía RBAC.
// - Sincroniza altas, cambios de puesto/rol (`Operador`, `Colaborador`,
//   `Operario`, `Supervisor`, `Administrador`, etc.) y eliminaciones tanto en
//   `PhotoDatabase.workers` como en `LocalDatabaseService.usuarios_locales`.
// POR QUÉ: Garantiza que los puestos creados por el Administrador, equipos y
//          sitios de trabajo con dirección sean 100% reales en SQLite (< 200 líneas).
// ============================================================================

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/utils/roles.dart';
import '../../../../core/validators/input_validators.dart';
import '../domain/local_actor.dart';
import '../domain/photo_record.dart';
import '../domain/shift_template.dart';
import '../domain/work_schedule.dart';
import 'journey_review_store.dart';
import 'local_shift_store.dart';
import 'photo_database.dart';
import 'worker_administration.dart';

class LocalAdminStore {
  LocalAdminStore(this.database, this.actor);
  final PhotoDatabase database;
  final LocalActor actor;
  late final _workers = WorkerAdministration(database, actor);
  String? get adminDocument => actor.document.isEmpty ? null : actor.document;

  late final LocalShiftStore _shiftStore = LocalShiftStore(
    database: database,
    requireAdmin: requireManagement,
    ensureDefaultData: ensureDefaultData,
    getSetting: setting,
  );

  void requireAdmin() {
    if (!actor.isStrictAdmin || adminDocument == null) {
      throw const FormatException('Acción exclusiva del administrador.');
    }
  }

  void requireManagement() {
    if ((!actor.isStrictAdmin && !actor.isSupervisor) || adminDocument == null) {
      throw const FormatException('Acción exclusiva de administradores o supervisores.');
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

  /// QUÉ HACE: Obtiene los puestos personalizados creados por el Administrador.
  Future<List<String>> customJobPositions() async {
    final raw = await setting('custom_job_positions');
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List).map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  /// QUÉ HACE: Permite al Administrador crear un nuevo puesto laboral aplicable en equipos y personal.
  Future<List<String>> addCustomJobPosition(String position) async {
    requireAdmin();
    final clean = position.trim();
    if (clean.length < 2) throw const FormatException('Ingresa un nombre válido para el puesto.');
    final current = await customJobPositions();
    if (!current.any((p) => p.toLowerCase() == clean.toLowerCase()) &&
        !AppRoles.rolesForAdmin.any((p) => p.toLowerCase() == clean.toLowerCase())) {
      final updated = [...current, clean];
      await saveSetting('custom_job_positions', jsonEncode(updated));
      return updated;
    }
    return current;
  }

  /// QUÉ HACE: Obtiene los puestos habilitados en una cuadrilla (ej. Operador, Colaborador, Operario).
  Future<List<String>> crewPositions(int? crewId) async {
    if (crewId != null) {
      final raw = await setting('crew_positions_$crewId');
      if (raw != null && raw.isNotEmpty) {
        try {
          final list = (jsonDecode(raw) as List).map((e) => e.toString()).toList();
          if (list.isNotEmpty) return list;
        } catch (_) {}
      }
    }
    final custom = await customJobPositions();
    return ['Operador', 'Colaborador', 'Operario', 'Promotor', 'Técnico de Campo', ...custom];
  }

  /// QUÉ HACE: Guarda los puestos habilitados para una cuadrilla específica.
  Future<void> saveCrewPositions(int crewId, List<String> positions) async {
    requireManagement();
    final clean = positions.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    await (await database.database).insert(
      'local_settings',
      {'name': 'crew_positions_$crewId', 'value': jsonEncode(clean)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> rows(String table) async {
    if (!const ['crews', 'work_zones', 'workers'].contains(table)) throw ArgumentError('Tabla no permitida: $table');
    await ensureDefaultData();
    final isWorkers = table == 'workers';
    return (await database.database).query(
      table,
      where: (actor.isStrictAdmin || isWorkers) ? null : (table == 'crews' ? 'supervisor_document=?' : 'id IN (SELECT zone_id FROM crews WHERE supervisor_document=?)'),
      whereArgs: (actor.isStrictAdmin || isWorkers) ? null : [actor.document.trim()],
      orderBy: 'name',
    );
  }

  Future<List<Map<String, Object?>>> crewsWithZones() async {
    await ensureDefaultData();
    return (await database.database).rawQuery('''
      SELECT c.*, z.name as zone_name, z.address as zone_address, z.radius_m as zone_radius,
             z.latitude as zone_lat, z.longitude as zone_lng
      FROM crews c LEFT JOIN work_zones z ON c.zone_id = z.id
      ${actor.isStrictAdmin ? '' : 'WHERE c.supervisor_document=?'} ORDER BY c.name''',
      actor.isStrictAdmin ? [] : [actor.document.trim()]);
  }

  /// QUÉ HACE: Guarda o crea un sitio de trabajo con dirección (`work_zones`).
  /// Permite tanto al Administrador como al Supervisor de cuadrilla registrar sitios.
  Future<int> saveZone(Map<String, Object?> zone, {int? id}) async {
    requireManagement();
    final lat = (zone['latitude'] as num).toDouble(), lng = (zone['longitude'] as num).toDouble(), rad = (zone['radius_m'] as num).toDouble();
    if ((zone['name'] as String).trim().isEmpty || !lat.isFinite || lat.abs() > 90 || !lng.isFinite || lng.abs() > 180 || !rad.isFinite || rad < 20 || rad > 50000) {
      throw const FormatException('Revisa nombre, coordenadas y radio (20 a 50000 metros).');
    }
    final db = await database.database;
    return id == null ? await db.insert('work_zones', zone) : (await db.update('work_zones', zone, where: 'id=?', whereArgs: [id]), id).$2;
  }

  /// QUÉ HACE: Crea o actualiza una cuadrilla (`crews`) y devuelve su `id`.
  Future<int> saveCrew(Map<String, Object?> crew, {int? id}) async {
    requireManagement();
    final from = DateTime.tryParse(crew['valid_from'] as String), until = DateTime.tryParse(crew['valid_until'] as String);
    if ((crew['name'] as String).trim().isEmpty || from == null || until == null || until.isBefore(from) || InputValidators.validateCedula(crew['supervisor_document'] as String) != null) {
      throw const FormatException('Revisa nombre, cédula del supervisor y período.');
    }
    if (!actor.isStrictAdmin && actor.isSupervisor && (crew['supervisor_document'] as String).trim() != actor.document.trim()) {
      throw const FormatException('El supervisor solo puede gestionar su propia cuadrilla.');
    }
    final driver = crew['driver_document'] as String?;
    if (driver != null && driver.isNotEmpty && !RegExp(r'^\d{3,20}$').hasMatch(driver)) throw const FormatException('Identificación adicional inválida.');
    final db = await database.database;
    final supDoc = (crew['supervisor_document'] as String).trim();
    if (id != null) {
      await _workers.requireCrew(db, id);
      await db.update('crews', crew, where: 'id=?', whereArgs: [id]);
      await db.update('workers', {'crew_id': id}, where: 'document=?', whereArgs: [supDoc]);
      return id;
    }
    final newId = await db.insert('crews', crew);
    await db.update('workers', {'crew_id': newId}, where: 'document=?', whereArgs: [supDoc]);
    return newId;
  }

  /// QUÉ HACE: Asigna cuadrilla, horario y puesto/rol y sincroniza login.
  Future<void> assignWorker(int workerId, int? crewId, WorkSchedule? schedule, String authorizationReference, {String? role}) async {
    requireManagement();
    await ensureDefaultData();
    final authRef = authorizationReference.trim().isNotEmpty ? authorizationReference.trim() : 'Asignación administrativa';
    if (schedule != null && (schedule.dailyMinutes <= 0 || schedule.dailyMinutes > 1440 || schedule.nightStartMinute == schedule.nightEndMinute)) {
      throw const FormatException('Duración de jornada inválida.');
    }
    await _workers.assign(workerId, crewId, schedule, authRef, role: role);
  }

  Future<Map<String, Object?>> workerConfig(int id) async {
    requireManagement();
    return _workers.worker(await database.database, id);
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
    await LocalShiftStore.seedDefaultShifts(db);
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
    requireManagement();
    final db = await database.database;
    if (!actor.isStrictAdmin && actor.isSupervisor && (await db.query('crews', where: 'id=? AND supervisor_document=?', whereArgs: [id, actor.document.trim()])).isEmpty) {
      throw const FormatException('Solo puedes eliminar tu propia cuadrilla.');
    }
    await db.transaction((txn) async {
      await _workers.requireCrew(txn, id);
      await txn.update('workers', {'crew_id': null}, where: 'crew_id=?', whereArgs: [id]);
      await txn.delete('crews', where: 'id=?', whereArgs: [id]);
    });
  }

  Future<void> deleteWorker(int id) async { requireManagement(); await _workers.delete(id); }

  Future<void> setWorkerCrew(int workerId, int? crewId, {String? role}) async {
    requireManagement();
    final current = await workerConfig(workerId);
    await _workers.assign(workerId, crewId, WorkSchedule.decode(current['schedule_json'] as String?), 'Cambio de equipo', role: role);
  }

  Future<void> setWorkerPassword(int workerId, String password) async { requireManagement(); await _workers.setPassword(workerId, password); }
  Future<List<ShiftTemplate>> shiftTemplates() => _shiftStore.shiftTemplates();
  Future<void> saveShiftTemplate(ShiftTemplate t) => _shiftStore.saveShiftTemplate(t);
  Future<void> deleteShiftTemplate(int id) => _shiftStore.deleteShiftTemplate(id);
  Future<void> assignShiftToWorkers({required List<int> workerIds, required ShiftTemplate template, String? reference}) => _shiftStore.assignShiftToWorkers(workerIds: workerIds, template: template, reference: reference);
  Future<void> removeScheduleFromWorker(int workerId) => _shiftStore.removeScheduleFromWorker(workerId);
  Future<List<PhotoDay>> allOvertimeDays() => _shiftStore.allOvertimeDays();
}
