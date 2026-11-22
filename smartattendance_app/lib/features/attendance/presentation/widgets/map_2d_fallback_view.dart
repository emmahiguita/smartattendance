// ============================================================================
// ARCHIVO: map_2d_fallback_view.dart
// QUÉ HACE: Visor cartográfico 2D (`FlutterMap`) para modos Satélite/Topo/2D
//           con geocercas sonar, tráfico, radar de lluvia y ruta vial OSRM.
// CÓMO FUNCIONA: Recibe el estado del tracker y `MapController` ya instanciado
//                por `MapTabScreen` sin duplicar lógica de permisos ni red.
// POR QUÉ: Desacopla la vista 2D de la orquestación de `MapTabScreen` (< 95 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../photo_attendance/domain/work_zone.dart';
import 'map_sonar_layer.dart';
import 'map_traffic_overlay.dart';
import 'map_weather_overlay.dart';

class Map2DFallbackView extends StatelessWidget {
  const Map2DFallbackView({
    super.key,
    required this.mapController,
    required this.pulseController,
    required this.style,
    required this.userPoint,
    required this.zonePoint,
    required this.zones,
    required this.activeZone,
    required this.hasFix,
    required this.isInsideZone,
    required this.accuracy,
    required this.heading,
    required this.trafficEnabled,
    required this.weatherRadarEnabled,
    this.radarTileUrl,
    this.zoneRadius = 80.0,
    this.zoneName,
    this.routePoints = const [],
    this.onTapUser,
  });

  final MapController mapController;
  final AnimationController pulseController;
  final MapCartoStyle style;
  final LatLng userPoint, zonePoint;
  final List<WorkZone> zones;
  final WorkZone? activeZone;
  final bool hasFix, isInsideZone, trafficEnabled, weatherRadarEnabled;
  final double accuracy, heading, zoneRadius;
  final String? radarTileUrl, zoneName;
  final List<LatLng> routePoints;
  final VoidCallback? onTapUser;

  @override
  Widget build(BuildContext context) {
    final pts = routePoints.length >= 2
        ? routePoints
        : (hasFix && activeZone != null ? [userPoint, zonePoint] : const <LatLng>[]);

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: userPoint,
        initialZoom: 16.5,
        minZoom: 3.0,
        maxZoom: 20.0,
      ),
      children: [
        MapBaseTileLayer(style: style),
        MapTrafficOverlay(enabled: trafficEnabled),
        MapWeatherOverlay(enabled: weatherRadarEnabled, radarTileUrl: radarTileUrl),
        if (pts.length >= 2)
          PolylineLayer(polylines: [
            Polyline(
              points: pts,
              strokeWidth: routePoints.length >= 2 ? 5.0 : 2.8,
              color: routePoints.length >= 2
                  ? const Color(0xFF0A84FF)
                  : (isInsideZone ? AppColors.successDark : const Color(0xFF007AFF)),
            ),
          ]),
        for (final z in zones.where((z) => z.id != activeZone?.id))
          CircleLayer(circles: [
            CircleMarker(
              point: LatLng(z.latitude, z.longitude),
              radius: z.radius,
              useRadiusInMeter: true,
              color: Colors.blue.withValues(alpha: 0.08),
              borderColor: const Color(0xFF007AFF).withValues(alpha: 0.45),
              borderStrokeWidth: 1.2,
            ),
          ]),
        MapSonarCircleLayer(
          point: zonePoint,
          pulseAnimation: pulseController,
          zoneRadiusMeters: activeZone?.radius ?? zoneRadius,
          isInside: isInsideZone,
          zoneName: activeZone?.name ?? zoneName,
        ),
        MapUserLocationMarkerLayer(
          point: userPoint,
          hasFix: hasFix,
          accuracyMeters: accuracy,
          heading: heading,
          isInside: isInsideZone,
          pulseAnimation: pulseController,
          userLabel: 'Tu ubicación',
          onTap: onTapUser,
        ),
      ],
    );
  }
}
