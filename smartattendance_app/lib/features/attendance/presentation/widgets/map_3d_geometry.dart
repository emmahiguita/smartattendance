// ============================================================================
// ARCHIVO: map_3d_geometry.dart
// QUÉ HACE: Utilidades geométricas puras para proyectar geocercas circulares
//           en metros y rutas viales reales sobre el plano 3D de MapLibre.
// CÓMO FUNCIONA: Convierte radios en metros a polígonos geodésicos cerrados
//                de 48 vértices (`Feature<Polygon>`) y listas `LatLng` en
//                `Feature<LineString>` compatibles con `maplibre` / `geobase`.
// POR QUÉ: Separa la matemática geodésica de la vista 3D cumpliendo SRP (< 70 líneas).
// ============================================================================

import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:maplibre/maplibre.dart';

abstract final class Map3DGeometry {
  static const double _earthRadiusM = 6378137.0;

  // QUÉ HACE: Convierte un `LatLng` de `latlong2` al `Geographic` de `maplibre`.
  static Geographic toGeographic(LatLng pt) =>
      Geographic(lon: pt.longitude, lat: pt.latitude);

  // QUÉ HACE: Genera un polígono circular exacto en metros sobre el terreno 3D.
  // CÓMO: Proyecta `steps` puntos equidistantes usando corrección de coseno de latitud.
  // POR QUÉ: Permite que las geocercas se inclinen fielmente en perspectiva 3D (60°).
  static Feature<Polygon> circlePolygon({
    required double lat,
    required double lng,
    required double radiusMeters,
    int steps = 48,
  }) {
    final safeRadius = radiusMeters.clamp(10.0, 50000.0);
    final latRad = lat * math.pi / 180.0;
    final dLat = (safeRadius / _earthRadiusM) * (180.0 / math.pi);
    final cosLat = math.cos(latRad).abs().clamp(0.01, 1.0);
    final dLng = dLat / cosLat;

    final ring = <Geographic>[];
    for (var i = 0; i <= steps; i++) {
      final theta = (i * 2.0 * math.pi) / steps;
      ring.add(Geographic(
        lon: lng + dLng * math.cos(theta),
        lat: lat + dLat * math.sin(theta),
      ));
    }
    return Feature<Polygon>(geometry: Polygon.from([ring]));
  }

  // QUÉ HACE: Convierte una ruta vial (o línea origen-destino) en `Feature<LineString>`.
  static Feature<LineString> routeLine(List<LatLng> points) =>
      Feature<LineString>(
        geometry: LineString.from(points.map(toGeographic)),
      );
}
