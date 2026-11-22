// ============================================================================
// ARCHIVO: osrm_routing_service.dart
// QUÉ HACE: Servicio gratuito de enrutamiento vial real (estilo Waze / Google)
//           basado en OSRM OpenStreetMap para trazar rutas calle por calle,
//           calcular distancia real de conducción y tiempo estimado (ETA).
// CÓMO FUNCIONA: Define la interfaz `NavigationRoutingProvider` (DIP) y su
//                implementación `OsrmRoutingService` que consulta el endpoint
//                público OSRM en formato GeoJSON y cierra el cliente `Dio`.
// POR QUÉ: Reemplaza líneas rectas por rutas viales reales 100% gratis sin API
//          keys y cumple principios SOLID y cero fugas de sockets (< 120 líneas).
// ============================================================================

import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Resultado inmutable de una ruta vial real calculada por calles.
class RoadRouteResult {
  const RoadRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  // QUÉ HACE: Formatea la distancia vial real en metros o kilómetros legibles.
  String get distanceLabel => distanceMeters >= 1000
      ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
      : '${distanceMeters.round()} m';

  // QUÉ HACE: Formatea el tiempo estimado de llegada (ETA) en horas/minutos.
  String get durationLabel {
    final totalMin = (durationSeconds / 60).round().clamp(1, 9999);
    if (totalMin < 60) return '$totalMin min';
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

/// Contrato desacoplado (DIP) para motores de enrutamiento vial.
abstract interface class NavigationRoutingProvider {
  Future<RoadRouteResult?> fetchDrivingRoute({
    required LatLng origin,
    required LatLng destination,
  });
}

/// Implementación real gratuita con OSRM (Open Source Routing Machine).
class OsrmRoutingService implements NavigationRoutingProvider {
  const OsrmRoutingService();

  // QUÉ HACE: Solicita a OSRM la geometría real por calles entre origen y destino.
  // CÓMO: Invoca GET `/route/v1/driving/{lon1},{lat1};{lon2},{lat2}` en GeoJSON
  //       y cierra el cliente `Dio` en `finally` para evitar fugas de sockets.
  // POR QUÉ: Permite navegación vial real gratuita estilo Waze dentro del mapa 3D.
  @override
  Future<RoadRouteResult?> fetchDrivingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      headers: const {'User-Agent': 'BuenTiempoAttendance/1.0'},
    ));
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}';
      final res = await dio.get<Map<String, dynamic>>(
        url,
        queryParameters: const {
          'overview': 'full',
          'geometries': 'geojson',
        },
      );
      final routes = res.data?['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final best = routes.first as Map<String, dynamic>;
      final geometry = best['geometry'] as Map<String, dynamic>?;
      final coords = geometry?['coordinates'] as List<dynamic>?;
      if (coords == null || coords.length < 2) return null;

      final pts = <LatLng>[];
      for (final c in coords) {
        if (c is List && c.length >= 2) {
          final lon = (c[0] as num).toDouble();
          final lat = (c[1] as num).toDouble();
          pts.add(LatLng(lat, lon));
        }
      }
      if (pts.length < 2) return null;

      return RoadRouteResult(
        points: pts,
        distanceMeters: (best['distance'] as num?)?.toDouble() ?? 0,
        durationSeconds: (best['duration'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return null;
    } finally {
      dio.close();
    }
  }
}
