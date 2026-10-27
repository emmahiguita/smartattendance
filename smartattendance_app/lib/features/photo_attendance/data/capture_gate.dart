// ============================================================================
// ARCHIVO: capture_gate.dart
// QUÉ HACE: Aplica las reglas y restricciones del Administrador y Supervisor:
//           1. Existencia del colaborador en base local.
//           2. Validación de geocerca GPS real en la zona asignada.
//           3. Validación del rango/ventana de horario permitida para marcar.
// CÓMO FUNCIONA: Consulta workers con join a crews y work_zones. Si el supervisor
//                configuró un rango de horas, valida `isTimeWithinMarkWindow`.
// POR QUÉ: Garantiza control de asistencia verídico sin simulación (< 90 líneas).
// ============================================================================

import 'package:sqflite/sqflite.dart';
import '../domain/attendance_location.dart';
import '../domain/local_actor.dart';
import '../domain/work_schedule.dart';
import '../domain/work_zone.dart';

class CaptureGate {
  const CaptureGate(this.actor);
  final LocalActor actor;

  /// Datos del trabajador + su zona. Lanza si el trabajador no existe.
  Future<Map<String, Object?>> employee(DatabaseExecutor db, int workerId) async {
    final rows = await db.rawQuery('''SELECT w.*, c.name crew_name,
      z.id zone_id, z.name zone_name, z.latitude zone_lat,
      z.longitude zone_lng, z.radius_m zone_radius
      FROM workers w
      LEFT JOIN crews c ON c.id=w.crew_id
      LEFT JOIN work_zones z ON z.id=c.zone_id
      WHERE w.id=?''', [workerId]);
    if (rows.isEmpty) {
      throw const FormatException('Trabajador no encontrado en el dispositivo.');
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

    // 1. Verificación de ventana horaria configurada por el supervisor
    final scheduleJson = row['schedule_json'] as String?;
    final schedule = WorkSchedule.decode(scheduleJson);
    if (schedule != null && !schedule.isTimeWithinMarkWindow(ColombiaClock.wall(DateTime.now()))) {
      throw FormatException(
          'Fuera del rango horario permitido para marcar (${schedule.markWindowFormatted}). '
          'Consulta con tu supervisor.');
    }

    // 2. Verificación de Geocerca GPS real
    final zoneId = row['zone_id'];
    if (zoneId == null) return row; // Sin zona asignada: sin restricción geográfica.

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