import 'attendance_location.dart';
import 'work_schedule.dart';
import 'work_totals.dart';

/// Dominio local: no depende de Flutter, SQLite, red ni autenticación remota.
class LocalWorker {
  const LocalWorker(
      {required this.id,
      required this.name,
      required this.document,
      required this.job,
      this.schedule,
      this.lastMark,
      this.lastMarkAt,
      this.lastWorkDate,
      this.lastJourneyStatus});
  final int id;
  final String name;
  final String document;
  final String job;
  final WorkSchedule? schedule;
  final String? lastMark;
  final DateTime? lastMarkAt;

  /// Fecha y estado de la jornada más reciente, consultados desde SQLite.
  final String? lastWorkDate;
  final String? lastJourneyStatus;
}

/// La foto acredita una captura; no identifica automáticamente a la persona.
class PhotoRecord {
  const PhotoRecord(
      {required this.uuid,
      required this.workerId,
      required this.name,
      required this.document,
      required this.job,
      required this.type,
      required this.capturedAt,
      required this.localPath,
      this.location,
      this.journeyId,
      this.operatorDocument});
  final String uuid;
  final int workerId;
  final String name;
  final String document;
  final String job;
  final String type;
  final DateTime capturedAt;
  final String localPath;

  /// Null solo para registros históricos anteriores a la integración GPS.
  final AttendanceLocation? location;
  final String? journeyId;
  final String? operatorDocument;
}

/// Puerto de persistencia: las pantallas no conocen SQL ni carpetas privadas.
abstract interface class LocalAttendanceRepository {
  /// Chequeo rápido previo a la cámara (el trabajador existe).
  Future<void> prepare(LocalWorker worker);
  Future<List<PhotoDay>> days(
      {int skip = 0, int limit = 20, String search = ''});
  Future<List<LocalWorker>> workers();
  Future<void> addWorker(String name, String document, String job);
  Future<PhotoRecord> capture(LocalWorker worker, String type, String imagePath,
      {required AttendanceLocation location, String? captureId});
  Future<List<PhotoRecord>> history(
      {int skip = 0, int limit = 50, String search = ''});
  Future<String> exportCsv();
}

/// Jornada visual: conserva TODAS las marcaciones del trabajador en ese día.
/// No sobrescribe horas si hay dos entradas, descansos o varios turnos.
class PhotoDay {
  const PhotoDay(this.records,
      {this.schedule,
      this.approvedSeconds,
      this.reviewedBy,
      this.reviewedAt,
      this.reviewNote,
      this.status = 'open'});
  final List<PhotoRecord> records;
  final WorkSchedule? schedule;
  final int? approvedSeconds;
  final String? reviewedBy, reviewedAt, reviewNote;
  final String status;
  String get id => worker.journeyId ?? worker.uuid;
  WorkTotals get totals => WorkTotals(records, schedule);
  PhotoRecord get worker => records.first;
  DateTime get date {
    final stamp = ColombiaClock.wall(worker.capturedAt);
    return DateTime(stamp.year, stamp.month, stamp.day);
  }

  List<PhotoRecord> marks(String type) =>
      records.where((r) => r.type == type).toList();
}
