/// Evidencia geográfica de una marcación; independiente de Flutter y Android.
/// La hora del sensor se conserva aparte de la hora de guardado de asistencia.
class AttendanceLocation {
  const AttendanceLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.fixedAt,
  });
  final double latitude, longitude, accuracy;
  final DateTime fixedAt;

  /// Texto común al historial y reportes: precisión estimada, no certificada.
  String get coordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  String get description =>
      '$coordinates · Precisión ${accuracy.toStringAsFixed(0)} m';
}

/// Puerto del dominio: guardar depende de una posición obtenida del dispositivo,
/// sin conocer plugins, mapas, conexiones a internet ni coordenadas por defecto.
abstract interface class AttendanceLocationSource {
  /// Lectura GPS fresca y validada. Lanza [FormatException] si no hay señal,
  /// permiso, o la ubicación es simulada/imprecisa.
  Future<AttendanceLocation> capture();

  /// true si el GPS está encendido y el permiso concedido. Permite pedir la
  /// ubicación en paralelo con la cámara SIN que el diálogo de permiso
  /// aparezca encima de la cámara (solo se paraleliza si ya hay permiso).
  Future<bool> ready();
}
