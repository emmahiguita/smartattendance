// lib/features/attendance/data/models/today_employee_status.dart

/// Estado de asistencia HOY de un empleado — devuelto por /attendance/today-status.
final class TodayEmployeeStatus {
  const TodayEmployeeStatus({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.cedula,
    this.cargo,
    this.fotoUrl,
    required this.estado,
    this.horaEntrada,
    this.minutosTarde = 0,
  });

  final int id;
  final String nombre;
  final String apellido;
  final String cedula;
  final String? cargo;
  final String? fotoUrl; // ruta relativa: /static/fotos/{filename}
  final String estado; // 'a_tiempo', 'tarde', 'sin_marcar'
  final String? horaEntrada; // 'HH:MM:SS' o null
  final int minutosTarde;

  String get fullName => '$nombre $apellido';

  String get initials =>
      '${nombre.isNotEmpty ? nombre[0] : ''}${apellido.isNotEmpty ? apellido[0] : ''}';

  factory TodayEmployeeStatus.fromJson(Map<String, dynamic> json) {
    return TodayEmployeeStatus(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      cedula: json['cedula'] as String,
      cargo: json['cargo'] as String?,
      fotoUrl: json['foto_url'] as String?,
      estado: json['estado'] as String,
      horaEntrada: json['hora_entrada'] as String?,
      minutosTarde: json['minutos_tarde'] as int? ?? 0,
    );
  }
}
