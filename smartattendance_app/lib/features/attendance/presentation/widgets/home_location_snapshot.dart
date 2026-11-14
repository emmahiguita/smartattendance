// QUÉ HACE: Resuelve horario, sede y posición reales para la pantalla de inicio.
// CÓMO: Lee exclusivamente la asignación de la identidad autenticada y el GPS.
// POR QUÉ: Una ausencia de datos no debe sustituirse por otra sede o jornada.
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

  // QUÉ HACE: Obtiene una instantánea coherente sin valores operativos ficticios.
  static Future<HomeLocationSnapshot> capture(
      Database db, String document) async {
    if (document.isEmpty) return const HomeLocationSnapshot();
    final workers = await db.query('workers',
        columns: ['schedule_json'],
        where: 'document = ?',
        whereArgs: [document],
        limit: 1);
    final schedule = workers.isEmpty
        ? null
        : WorkSchedule.decode(workers.first['schedule_json'] as String?);
    final zones = await db.rawQuery(
        'SELECT z.* FROM workers w JOIN crews c ON c.id = w.crew_id JOIN work_zones z ON z.id = c.zone_id WHERE w.document = ? LIMIT 1',
        [document]);
    final zone = zones.firstOrNull;
    final lat = (zone?['latitude'] as num?)?.toDouble();
    final lng = (zone?['longitude'] as num?)?.toDouble();
    final radius = (zone?['radius_m'] as num?)?.toDouble();
    final position = await const LocationService().capture();
    final distance = position != null && lat != null && lng != null
        ? const Distance().as(LengthUnit.Meter,
            LatLng(position.lat, position.lng), LatLng(lat, lng))
        : null;
    if (position != null) {
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
