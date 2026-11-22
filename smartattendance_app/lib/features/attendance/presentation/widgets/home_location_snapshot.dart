// ============================================================================
// ARCHIVO: home_location_snapshot.dart
// QUÉ HACE: Resuelve horario, sede y posición GPS reales para la pantalla Inicio.
// CÓMO FUNCIONA: Lee la asignación del colaborador o la sede institucional
//                principal en SQLite y captura posición GPS con respaldo nativo.
// POR QUÉ: Garantiza que el visor 3D de Inicio siempre disponga de GPS y geocerca.
// ============================================================================
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/location/traccar_service.dart';
import '../../../photo_attendance/domain/work_schedule.dart';

class HomeLocationSnapshot {
  const HomeLocationSnapshot(
      {this.latitude,
      this.longitude,
      this.zoneLat,
      this.zoneLng,
      this.radius,
      this.distance,
      this.name,
      this.address,
      this.schedule,
      this.inside = false});
  final double? latitude, longitude, zoneLat, zoneLng, radius, distance;
  final String? name, address;
  final WorkSchedule? schedule;
  final bool inside;

  // QUÉ HACE: Obtiene una instantánea real de GPS, horario y sede en SQLite.
  static Future<HomeLocationSnapshot> capture(
      Database db, String document) async {
    WorkSchedule? schedule;
    Map<String, Object?>? zone;
    if (document.isNotEmpty) {
      final workers = await db.query('workers',
          columns: ['schedule_json'],
          where: 'document = ?',
          whereArgs: [document],
          limit: 1);
      schedule = workers.isEmpty
          ? null
          : WorkSchedule.decode(workers.first['schedule_json'] as String?);
      final zones = await db.rawQuery(
          'SELECT z.* FROM workers w JOIN crews c ON c.id = w.crew_id JOIN work_zones z ON z.id = c.zone_id WHERE w.document = ? LIMIT 1',
          [document]);
      zone = zones.firstOrNull;
    }
    if (zone == null) {
      final fallbackZones =
          await db.query('work_zones', orderBy: 'id ASC', limit: 1);
      zone = fallbackZones.firstOrNull;
    }
    final lat = (zone?['latitude'] as num?)?.toDouble();
    final lng = (zone?['longitude'] as num?)?.toDouble();
    final radius = (zone?['radius_m'] as num?)?.toDouble();
    var position = await const LocationService().capture();
    if (position == null) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null &&
            !last.isMocked &&
            last.latitude.isFinite &&
            last.longitude.isFinite) {
          position = (lat: last.latitude, lng: last.longitude, dir: null);
        }
      } catch (_) {}
    }
    final distance = position != null && lat != null && lng != null
        ? const Distance().as(LengthUnit.Meter,
            LatLng(position.lat, position.lng), LatLng(lat, lng))
        : null;
    if (position != null && document.isNotEmpty) {
      const TraccarService().pushPosition(
          deviceId: document,
          latitude: position.lat,
          longitude: position.lng,
          zoneName: zone?['name'] as String?);
    }
    return HomeLocationSnapshot(
        latitude: position?.lat,
        longitude: position?.lng,
        zoneLat: lat,
        zoneLng: lng,
        radius: radius,
        distance: distance,
        name: zone?['name'] as String?,
        address: zone?['address'] as String?,
        schedule: schedule,
        inside: distance != null && radius != null && distance <= radius);
  }
}
