// QUÉ HACE: Describe un sitio explícito para el alta de personal.
// CÓMO: Transporta coordenadas reales elegidas por el administrador.
// POR QUÉ: El alta no inventa una ubicación ni modifica equipos por separado.
class WorkerSite {
  const WorkerSite({required this.name, required this.address, required this.latitude,
    required this.longitude, this.radius = 100});
  final String name, address;
  final double latitude, longitude, radius;
  bool get isValid => name.trim().isNotEmpty && address.trim().isNotEmpty &&
      latitude.isFinite && latitude.abs() <= 90 && longitude.isFinite &&
      longitude.abs() <= 180 && radius.isFinite && radius >= 20 && radius <= 50000;
  Map<String, Object?> toMap() => {'name': name.trim(), 'address': address.trim(),
    'latitude': latitude, 'longitude': longitude, 'radius_m': radius};
}
