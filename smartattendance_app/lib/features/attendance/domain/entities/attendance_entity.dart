// lib/features/attendance/domain/entities/attendance_entity.dart
import 'package:equatable/equatable.dart';

/// Attendance domain entity — pure Dart.
class AttendanceEntity extends Equatable {
  const AttendanceEntity({
    required this.id,
    required this.usuarioId,
    required this.fecha,
    required this.hora,
    required this.tipo,
    this.latitud,
    this.longitud,
    this.direccion,
    this.nombreEmpleado,
    this.apellidoEmpleado,
    this.cedulaEmpleado,
    this.cargoEmpleado,
  });

  final int id;
  final int usuarioId;
  final DateTime fecha;
  final DateTime hora;
  final String tipo; // 'entrada' | 'salida'
  final double? latitud;
  final double? longitud;
  final String? direccion;
  final String? nombreEmpleado;
  final String? apellidoEmpleado;
  final String? cedulaEmpleado;

  /// Área organizacional (cargo) del empleado — llega en /attendance/with-users.
  final String? cargoEmpleado;

  bool get isEntrada => tipo == 'entrada';

  String get fullName {
    if (nombreEmpleado != null && apellidoEmpleado != null) {
      return '$nombreEmpleado $apellidoEmpleado';
    }
    if (nombreEmpleado != null) return nombreEmpleado!;
    return 'Empleado #$usuarioId';
  }

  @override
  List<Object?> get props => [id];
}

/// Calcula el tiempo LABORADO REAL del día, procesando las marcas en orden
/// cronológico y soportando MÚLTIPLES jornadas el mismo día.
///
/// Cada ciclo entrada → salida_almuerzo → regreso_almuerzo → salida suma sus
/// tramos reales; una jornada en curso (entrada/regreso sin cierre) suma desde
/// su marca hasta ahora. No mezcla marcas de jornadas distintas (el bug del
/// `map[tipo] = hora` sobreescribía y daba 0h con jornada completa).
String calculateWorkedHoursLabel(
  Iterable<AttendanceEntity> dayRecords, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final sorted = List<AttendanceEntity>.from(dayRecords)
    ..sort((a, b) => a.hora.compareTo(b.hora));

  var totalMinutes = 0;

  // Normaliza la hora de cada marca a la FECHA LOCAL del registro: la hora
  // viene combinada con la fecha UTC del servidor, y las restas entre marcas
  // (o contra "ahora") solo son reales sobre la misma base local.
  DateTime localStamp(AttendanceEntity r) {
    final local = r.fecha.toLocal();
    return DateTime(
      local.year,
      local.month,
      local.day,
      r.hora.hour,
      r.hora.minute,
      r.hora.second,
    );
  }

  // Tramo A (entrada → salida_almuerzo, o → salida sin almuerzo).
  DateTime? tramoAInicio;
  // Tramo B (regreso_almuerzo → salida).
  DateTime? tramoBInicio;

  for (final r in sorted) {
    final stamp = localStamp(r);
    switch (r.tipo) {
      case 'entrada':
        // Nueva jornada (una entrada previa sin cierre se ignora por política:
        // el servidor marca el tipo; aquí solo se suma lo cerrado o en curso).
        tramoAInicio = stamp;
        tramoBInicio = null;
      case 'salida_almuerzo':
        if (tramoAInicio != null) {
          final diff = stamp.difference(tramoAInicio).inMinutes;
          if (diff > 0) totalMinutes += diff;
          tramoAInicio = null;
        }
      case 'regreso_almuerzo':
        tramoBInicio = stamp;
      case 'salida':
        if (tramoBInicio != null) {
          final diff = stamp.difference(tramoBInicio).inMinutes;
          if (diff > 0) totalMinutes += diff;
          tramoBInicio = null;
        } else if (tramoAInicio != null) {
          // Jornada SIN almuerzo: salida directa cierra el tramo A.
          final diff = stamp.difference(tramoAInicio).inMinutes;
          if (diff > 0) totalMinutes += diff;
          tramoAInicio = null;
        }
    }
  }

  // Jornadas en curso (se sigue trabajando): sumar hasta el momento actual.
  if (tramoAInicio != null) {
    final diff = current.difference(tramoAInicio).inMinutes;
    if (diff > 0) totalMinutes += diff;
  }
  if (tramoBInicio != null) {
    final diff = current.difference(tramoBInicio).inMinutes;
    if (diff > 0) totalMinutes += diff;
  }

  if (totalMinutes <= 0) return '0h 00m';
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}
