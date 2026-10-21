import '../domain/photo_record.dart';
import '../domain/attendance_location.dart';

/// Único punto de conversión SQLite → dominio; no duplica formatos en lectores.
PhotoRecord photoRecordFromRow(Map<String, Object?> row) => PhotoRecord(
    uuid: row['uuid'] as String,
    workerId: row['worker_id'] as int,
    name: row['name'] as String,
    document: row['document'] as String,
    job: row['job'] as String,
    type: row['type'] as String,
    capturedAt: DateTime.parse(row['captured_at'] as String).toLocal(),
    localPath: row['local_path'] as String,
    journeyId: row['journey_id'] as String?,
    operatorDocument: row['operator_document'] as String?,
    location: row['location_at'] == null
        ? null
        : AttendanceLocation(
            latitude: (row['latitude'] as num).toDouble(),
            longitude: (row['longitude'] as num).toDouble(),
            accuracy: (row['accuracy_m'] as num).toDouble(),
            fixedAt: DateTime.parse(row['location_at'] as String)));
