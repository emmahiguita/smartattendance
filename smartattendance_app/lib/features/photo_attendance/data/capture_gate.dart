// lib/features/photo_attendance/data/capture_gate.dart
import 'package:sqflite/sqflite.dart';
import '../domain/attendance_location.dart';
import '../domain/local_actor.dart';
import '../domain/work_zone.dart';

/// ============================================================================
/// SERVICIO DE CONTROL: CaptureGate (aplica las reglas del ADMINISTRADOR)
/// ============================================================================
/// QUÉ HACE:
/// 1. [employee]: comprueba que el trabajador exista y trae sus datos
///    (nombre, cargo, cuadrilla y zona asignada por el administrador).
/// 2. [check]: además verifica la GEOCERCA: si el administrador asignó una
///    zona a la cuadrilla del trabajador, la posición GPS real debe caer
///    dentro del radio de esa zona.
///
/// CÓMO FUNCIONA:
/// Un solo SELECT con LEFT JOIN workers → crews → work_zones. Si no hay zona
/// asignada, no se restringe (el admin no puso esa regla). Si la hay, se usa
/// [WorkZone.contains] (distancia Haversine + margen de precisión del GPS).
///
/// POR QUÉ:
/// Antes la consulta traía latitud/longitud/radio de la zona pero NUNCA los
/// usaba: la geocerca configurada por el administrador no tenía efecto
/// (componente sin lógica). La app no inventa reglas: solo aplica las suyas.
/// ============================================================================
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

  /// Igual que [employee] y además exige estar dentro de la zona asignada.
  Future<Map<String, Object?>> check(
    DatabaseExecutor db,
    int workerId,
    AttendanceLocation gps,
  ) async {
    final row = await employee(db, workerId);
    final zoneId = row['zone_id'];
    if (zoneId == null) return row; // El admin no asignó zona: sin restricción.

    final zone = WorkZone(
      zoneId as int,
      row['zone_name'] as String,
      (row['zone_lat'] as num).toDouble(),
      (row['zone_lng'] as num).toDouble(),
      (row['zone_radius'] as num).toDouble(),
    );
    if (!zone.contains(gps)) {
      throw FormatException(
          'Estás fuera de la zona "${zone.name}" asignada por el administrador '
          '(precisión GPS ${gps.accuracy.toStringAsFixed(0)} m).');
    }
    return row;
  }
}
