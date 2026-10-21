import 'package:sqflite/sqflite.dart';
import '../domain/photo_record.dart';
import '../domain/attendance_location.dart';
import 'photo_database.dart';
import 'photo_exporter.dart';
import 'photo_day_reader.dart';
import 'photo_row_mapper.dart';
import 'photo_mark_writer.dart';
import '../domain/work_schedule.dart';
import '../domain/local_actor.dart';

/// Caso de uso local: foto durable primero, fila después. Una escritura fallida
/// elimina únicamente la copia recién creada, nunca una foto del historial.
class PhotoRepository implements LocalAttendanceRepository {
  PhotoRepository(this.database, this.actor);
  final PhotoDatabase database;
  final LocalActor actor;

  @override
  Future<List<LocalWorker>> workers() async {
    final db = await database.database;
    return (await db.rawQuery('''SELECT w.*,
      CASE WHEN j.status='void' THEN NULL ELSE m.type END last_type,
      CASE WHEN j.status='void' THEN NULL ELSE m.captured_at END last_mark_at,
      CASE WHEN j.status='void' THEN NULL ELSE j.work_date END last_work_date,
      j.status last_journey_status
      FROM workers w
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
            lastMark: row['last_type'] as String?,
            lastMarkAt: row['last_mark_at'] == null
                ? null
                : DateTime.parse(row['last_mark_at'] as String),
            lastWorkDate: row['last_work_date'] as String?,
            lastJourneyStatus: row['last_journey_status'] as String?))
        .toList();
  }

  @override
  Future<void> addWorker(String name, String document, String job) async {
    if (!actor.isAdmin) {
      throw const FormatException('Solo el administrador crea trabajadores.');
    }
    if (name.trim().isEmpty ||
        !RegExp(r'^\d{3,20}$').hasMatch(document.trim())) {
      throw const FormatException(
          'Escribe el nombre y una cédula de 3 a 20 dígitos.');
    }
    final db = await database.database;
    try {
      await db.insert('workers', {
        'name': name.trim(),
        'document': document.trim(),
        'job': job.trim()
      });
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const FormatException('Ya existe un trabajador con esa cédula.');
      }
      rethrow;
    }
  }

  @override
  Future<PhotoRecord> capture(LocalWorker worker, String type, String imagePath,
          {required AttendanceLocation location, String? captureId}) =>
      PhotoMarkWriter(database, actor).save(worker, type, imagePath,
          location: location, captureId: captureId);

  @override
  Future<void> prepare(LocalWorker worker) =>
      PhotoMarkWriter(database, actor).prepare(worker);

  /// Paginación SQL: no se cargan todas las fotos ni todas las filas en memoria.
  @override
  Future<List<PhotoRecord>> history(
      {int skip = 0, int limit = 50, String search = ''}) async {
    final db = await database.database;
    // Escapar LIKE evita que '%' o '_' alteren la búsqueda literal del usuario.
    final term = search
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
    final rows = await db.query('photo_marks',
        where:
            '${actor.visibleWorkers('worker_id')}${search.isEmpty ? '' : " AND (name LIKE ? ESCAPE '\\' OR document LIKE ? ESCAPE '\\')"}',
        whereArgs: [
          ...actor.visibilityArgs,
          if (search.isNotEmpty) ...['%$term%', '%$term%']
        ],
        orderBy: 'captured_at DESC, uuid DESC',
        limit: limit,
        offset: skip);
    return rows.map(photoRecordFromRow).toList();
  }

  @override
  Future<List<PhotoDay>> days(
          {int skip = 0, int limit = 20, String search = ''}) =>
      PhotoDayReader(database, actor)
          .read(skip: skip, limit: limit, search: search);

  @override
  Future<String> exportCsv() => PhotoExporter(database, actor).export();
}
