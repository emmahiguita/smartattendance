import '../domain/photo_record.dart';
import '../domain/work_schedule.dart';
import 'photo_database.dart';
import 'photo_row_mapper.dart';
import '../domain/local_actor.dart';

/// Pagina jornadas completas, sin separar los turnos que cruzan medianoche.
/// El JOIN usa el identificador de entrada, no la fecha de cada foto.
class PhotoDayReader {
  PhotoDayReader(this.database, this.actor);
  final PhotoDatabase database;
  final LocalActor actor;
  Future<List<PhotoDay>> read(
      {int skip = 0, int limit = 20, String search = ''}) async {
    final db = await database.database;
    final term = search
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
    final filter =
        'WHERE ${actor.visibleWorkers('worker_id')}${search.isEmpty ? '' : " AND (name LIKE ? ESCAPE '\\' OR document LIKE ? ESCAPE '\\')"}';
    final rows = await db.rawQuery('''SELECT m.*, j.schedule_json, j.status,
      j.approved_seconds, j.reviewed_by, j.reviewed_at, j.review_note,
      z.name zone_name
      FROM photo_marks m JOIN journeys j ON j.id=m.journey_id
      LEFT JOIN workers w ON w.id=m.worker_id
      LEFT JOIN crews c ON c.id=w.crew_id
      LEFT JOIN work_zones z ON z.id=c.zone_id
      JOIN (
        SELECT journey_id, MAX(captured_at) latest FROM photo_marks $filter
        GROUP BY journey_id ORDER BY latest DESC, journey_id LIMIT ? OFFSET ?
      ) g ON g.journey_id=m.journey_id
      ORDER BY g.latest DESC, g.journey_id, m.captured_at, m.uuid''', [
      ...actor.visibilityArgs,
      if (search.isNotEmpty) ...['%$term%', '%$term%'],
      limit,
      skip,
    ]);
    final groups = <String, List<Map<String, Object?>>>{};
    for (final row in rows) {
      groups.putIfAbsent(row['journey_id'] as String, () => []).add(row);
    }
    return groups.values.map((rows) {
      final info = rows.first;
      return PhotoDay(rows.map(photoRecordFromRow).toList(),
          schedule: WorkSchedule.decode(info['schedule_json'] as String?),
          status: info['status'] as String,
          approvedSeconds: info['approved_seconds'] as int?,
          reviewedBy: info['reviewed_by'] as String?,
          reviewedAt: info['reviewed_at'] as String?,
          reviewNote: info['review_note'] as String?,
          zoneName: info['zone_name'] as String?);
    }).toList();
  }
}
