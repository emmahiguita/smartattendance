// lib/features/attendance/data/models/attendance_model.dart
import '../../domain/entities/attendance_entity.dart';

final class AttendanceModel extends AttendanceEntity {
  const AttendanceModel({
    required super.id,
    required super.usuarioId,
    required super.tipo,
    required super.fecha,
    required super.hora,
    super.latitud,
    super.longitud,
    super.direccion,
    super.nombreEmpleado,
    super.apellidoEmpleado,
    super.cedulaEmpleado,
    super.cargoEmpleado,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    // Parsear la fecha del registro
    final fecha = DateTime.parse(json['fecha'] as String);

    // Parsear hora del string 'HH:mm:ss[.ffffff]' (el backend incluye
    // microsegundos) y combinar con la fecha real del registro.
    final parts = json['hora'].toString().split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final secStr = parts.length > 2 ? parts[2].split('.').first : '0';
    final s = int.tryParse(secStr) ?? 0;

    return AttendanceModel(
      id: json['id'] as int,
      usuarioId: json['usuario_id'] as int,
      tipo: json['tipo'] as String,
      fecha: fecha,
      // El backend registra en la zona de NEGOCIO (America/Bogota, UTC-5 fijo
      // sin DST). Se convierte a la hora local del dispositivo para que la
      // app muestre SIEMPRE la hora real del país, aunque el teléfono esté en
      // otro huso horario. (En Colombia la conversión es identidad.)
      hora: _bogotaToLocal(fecha, h, m, s),
      latitud:
          json['latitud'] != null ? (json['latitud'] as num).toDouble() : null,
      longitud: json['longitud'] != null
          ? (json['longitud'] as num).toDouble()
          : null,
      direccion: json['direccion'] as String?,
      nombreEmpleado: json['nombre'] as String?,
      apellidoEmpleado: json['apellido'] as String?,
      cedulaEmpleado: json['cedula'] as String?,
      cargoEmpleado: json['cargo'] as String?,
    );
  }

  /// Hora de Bogotá (UTC-5) → hora local del dispositivo.
  /// 22:06 en Bogotá = 03:06 UTC → .toLocal() lo convierte al huso activo.
  static DateTime _bogotaToLocal(DateTime fechaBase, int h, int m, int s) {
    final enUtc =
        DateTime.utc(fechaBase.year, fechaBase.month, fechaBase.day, h, m, s)
            .add(const Duration(hours: 5));
    return enUtc.toLocal();
  }

  // toEntity() eliminado: AttendanceModel ES AttendanceEntity (herencia directa)
  // Usar `this` directamente donde se necesite AttendanceEntity
}
