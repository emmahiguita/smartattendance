// ============================================================================
// ARCHIVO: capture_gate.dart
// QUÉ HACE: Aplica las reglas de seguridad y restricciones del Administrador:
//           1. Autorización del operador sobre el colaborador (`visibleWorkers`).
//           2. Validación de la ventana horaria permitida (`isTimeWithinMarkWindow`).
//           3. Validación de la geocerca GPS real en la zona asignada.
// CÓMO FUNCIONA: Consulta `workers` filtrando por `actor.visibleWorkers('w.id')`,
//                verifica el horario asignado y la distancia Haversine al punto GPS.
// POR QUÉ: Impide suplantación entre empleados y marcaciones fuera de regla (< 85 líneas).
// ============================================================================

import 'package:sqflite/sqflite.dart';
import '../domain/attendance_location.dart';
import '../domain/local_actor.dart';
import '../domain/work_schedule.dart';
import '../domain/work_zone.dart';

class CaptureGate {
  const CaptureGate(this.actor);
  final LocalActor actor;

  /// Datos del trabajador + su zona, exigiendo permiso de visibilidad del actor.
  Future<Map<String, Object?>> employee(DatabaseExecutor db, int workerId) async {
    final rows = await db.rawQuery('''SELECT w.*, c.name crew_name,
      z.id zone_id, z.name zone_name, z.latitude zone_lat,
      z.longitude zone_lng, z.radius_m zone_radius
      FROM workers w
      LEFT JOIN crews c ON c.id=w.crew_id
      LEFT JOIN work_zones z ON z.id=c.zone_id
      WHERE w.id=? AND ${actor.visibleWorkers('w.id')}''', [
      workerId,
      ...actor.visibilityArgs,
    ]);
    if (rows.isEmpty) {
      throw const FormatException(
          'No tienes permiso para registrar asistencia de este colaborador.');
    }
    return rows.first;
  }

  /// Verifica geocerca asignada Y ventana horaria permitida para marcar.
  Future<Map<String, Object?>> check(
    DatabaseExecutor db,
    int workerId,
    AttendanceLocation gps,
  ) async {
    final row = await employee(db, workerId);

    // 1. Verificación de ventana horaria configurada por el administrador
    final scheduleJson = row['schedule_json'] as String?;
    final schedule = WorkSchedule.decode(scheduleJson);
    if (schedule != null &&
        !schedule.isTimeWithinMarkWindow(ColombiaClock.wall(DateTime.now()))) {
      throw FormatException(
          'Fuera del rango horario permitido para marcar (${schedule.markWindowFormatted}). '
          'Consulta con tu supervisor.');
    }

    // 2. Verificación de Geocerca GPS real
    final zoneId = row['zone_id'];
    if (zoneId == null) return row;

    final zone = WorkZone(
      zoneId as int,
      row['zone_name'] as String,
      (row['zone_lat'] as num).toDouble(),
      (row['zone_lng'] as num).toDouble(),
      (row['zone_radius'] as num).toDouble(),
    );
    if (!zone.contains(gps)) {
      throw FormatException(
          'Estás fuera de la zona "${zone.name}" asignada '
          '(precisión GPS ${gps.accuracy.toStringAsFixed(0)} m).');
    }
    return row;
  }
}
