import 'dart:math' as math;
import 'attendance_location.dart';

/// Geocerca circular local, independiente del visor. El margen de precisión
/// debe quedar dentro: un punto dudoso en el borde no autoriza la marcación.
class WorkZone {
  const WorkZone(
      this.id, this.name, this.latitude, this.longitude, this.radius);
  final int id;
  final String name;
  final double latitude, longitude, radius;
  bool contains(AttendanceLocation location) {
    const radians = math.pi / 180;
    final a = math.pow(
            math.sin((location.latitude - latitude) * radians / 2), 2) +
        math.cos(latitude * radians) *
            math.cos(location.latitude * radians) *
            math.pow(
                math.sin((location.longitude - longitude) * radians / 2), 2);
    final distance = 6371000 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
    return distance + location.accuracy <= radius;
  }

  static WorkZone fromRow(Map<String, Object?> row) => WorkZone(
      row['id'] as int,
      row['name'] as String,
      (row['latitude'] as num).toDouble(),
      (row['longitude'] as num).toDouble(),
      (row['radius_m'] as num).toDouble());
}
