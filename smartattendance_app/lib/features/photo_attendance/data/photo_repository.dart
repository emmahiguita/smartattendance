// ============================================================================
// ARCHIVO: photo_repository.dart
// QUÉ HACE: Repositorio SQLite local de colaboradores, supervisores y
//           administradores, marcaciones biométricas con GPS real y CSV.
// CÓMO FUNCIONA:
// 1. `workers()` ejecuta un LEFT JOIN entre `workers`, `crews`, `work_zones`
//    y la última marca de la jornada aplicando `actor.visibleWorkers`.
// 2. `addWorker()` inserta en `workers` y sincroniza inmediatamente la cuenta
//    en `usuarios_locales` (`LocalDatabaseService`) para que el nuevo
//    Colaborador, Supervisor o Administrador pueda iniciar sesión al instante.
// POR QUÉ: Garantiza alta inmediata para login y cumple SRP (< 150 líneas).
// ============================================================================

import 'package:sqflite/sqflite.dart';
import '../../../../core/localstore/local_database_service.dart';
import '../../auth/data/datasources/local_auth_datasource.dart';
import '../domain/attendance_location.dart';
import '../domain/local_actor.dart';
import '../domain/photo_record.dart';
import '../domain/work_schedule.dart';
import 'photo_database.dart';
import 'photo_day_reader.dart';
import 'photo_exporter.dart';
import 'photo_mark_writer.dart';
import 'photo_row_mapper.dart';

class PhotoRepository implements LocalAttendanceRepository {
  PhotoRepository(this.database, this.actor);
  final PhotoDatabase database;
  final LocalActor actor;

  @override
  Future<List<LocalWorker>> workers() async {
    final db = await database.database;
    return (await db.rawQuery('''SELECT w.*,
      c.name crew_name, z.name zone_name,
      CASE WHEN j.status='void' THEN NULL ELSE m.type END last_type,
      CASE WHEN j.status='void' THEN NULL ELSE m.captured_at END last_mark_at,
      CASE WHEN j.status='void' THEN NULL ELSE j.work_date END last_work_date,
      j.status last_journey_status
      FROM workers w
      LEFT JOIN crews c ON c.id=w.crew_id
      LEFT JOIN work_zones z ON z.id=c.zone_id
      LEFT JOIN photo_marks m ON m.uuid=(
        SELECT latest.uuid FROM photo_marks latest
        WHERE latest.worker_id=w.id
        ORDER BY latest.captured_at DESC,latest.uuid DESC LIMIT 1)
      LEFT JOIN journeys j ON j.id=m.journey_id
      WHERE ${actor.visibleWorkers('w.id')}
    ORDER BY w.name COLLATE NOCASE''', actor.visibilityArgs))
        .map((row) => LocalWorker(
            id: row['id'] as int,
            name: row['name'] as String,
            document: row['document'] as String,
            job: row['job'] as String,
            schedule: WorkSchedule.decode(row['schedule_json'] as String?),
            crewId: row['crew_id'] as int?,
            crewName: row['crew_name'] as String?,
            zoneName: row['zone_name'] as String?,
            lastMark: row['last_type'] as String?,
            lastMarkAt: row['last_mark_at'] == null
                ? null
                : DateTime.parse(row['last_mark_at'] as String),
            lastWorkDate: row['last_work_date'] as String?,
            lastJourneyStatus: row['last_journey_status'] as String?))
        .toList();
  }

  @override
  Future<void> addWorker(
    String name,
    String document,
    String job, {
    int? crewId,
    WorkSchedule? schedule,
    String? authorizationReference,
  }) async {
    final cleanDoc = document.trim();
    final cleanName = name.trim();
    final cleanJob = job.trim().isEmpty ? 'Colaborador' : job.trim();

    if (!actor.isAdmin && cleanDoc != actor.document.trim()) {
      throw const FormatException('Acción exclusiva del administrador o supervisor.');
    }
    if (cleanName.isEmpty || !RegExp(r'^\d{3,20}$').hasMatch(cleanDoc)) {
      throw const FormatException('Escribe el nombre y una cédula de 3 a 20 dígitos.');
    }
    final db = await database.database;
    try {
      final newId = await db.insert('workers', {
        'name': cleanName,
        'document': cleanDoc,
        'job': cleanJob,
        if (crewId != null && actor.isAdmin) 'crew_id': crewId,
        if (schedule != null && actor.isAdmin) 'schedule_json': schedule.encode(),
        'authorization_reference': authorizationReference ?? 'Registro de personal en campo',
        'authorization_policy': 'Política General SmartAttendance',
        'authorization_at': DateTime.now().toUtc().toIso8601String(),
      });

      final parts = cleanName.split(RegExp(r'\s+'));
      await LocalDatabaseService().insertLocalUser({
        'id': newId,
        'cedula': cleanDoc,
        'nombre': parts.first,
        'apellido': parts.length > 1 ? parts.sublist(1).join(' ') : '',
        'correo': '',
        'cargo': cleanJob,
        'is_admin': LocalAuthDataSource.isRoleAdmin(cleanJob, cleanDoc) ? 1 : 0,
      });
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const FormatException('Ya existe una persona registrada con esa cédula.');
      }
      rethrow;
    }
  }

  @override
  Future<PhotoRecord> capture(LocalWorker worker, String type, String imagePath,
          {required AttendanceLocation location, String? captureId}) =>
      PhotoMarkWriter(database, actor)
          .save(worker, type, imagePath, location: location, captureId: captureId);

  @override
  Future<void> prepare(LocalWorker worker) =>
      PhotoMarkWriter(database, actor).prepare(worker);

  @override
  Future<List<PhotoRecord>> history(
      {int skip = 0, int limit = 50, String search = ''}) async {
    final db = await database.database;
    final term = search.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
    final rows = await db.query(
      'photo_marks',
      where:
          '${actor.visibleWorkers('worker_id')}${search.isEmpty ? '' : " AND (name LIKE ? ESCAPE '\\' OR document LIKE ? ESCAPE '\\')"}',
      whereArgs: [
        ...actor.visibilityArgs,
        if (search.isNotEmpty) ...['%$term%', '%$term%']
      ],
      orderBy: 'captured_at DESC, uuid DESC',
      limit: limit,
      offset: skip,
    );
    return rows.map(photoRecordFromRow).toList();
  }

  @override
  Future<List<PhotoDay>> days({int skip = 0, int limit = 20, String search = ''}) =>
      PhotoDayReader(database, actor).read(skip: skip, limit: limit, search: search);

  @override
  Future<String> exportCsv() => PhotoExporter(database, actor).export();
}
