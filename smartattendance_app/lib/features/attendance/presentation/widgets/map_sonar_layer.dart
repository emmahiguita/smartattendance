// ============================================================================
// ARCHIVO: map_sonar_layer.dart
// QUÉ HACE: Define los estilos cartográficos (`MapCartoStyle`) y las capas
//           reutilizables de teselas, geocerca sonar y marcador GPS.
// CÓMO FUNCIONA: Interpola las ondas concéntricas mediante `Animation<double>`
//                sobre `CircleLayer` y `MarkerLayer` de `FlutterMap`.
// POR QUÉ: Cumple SRP (< 190 líneas) y unifica el renderizado entre la tarjeta
//          de Inicio y el visor de pantalla completa.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';

enum MapCartoStyle {
  streets(
    'Calles',
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    Icons.map_rounded,
  ),
  satellite(
    'Satélite',
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    Icons.satellite_alt_rounded,
  ),
  topo(
    'Topográfico',
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
    Icons.terrain_rounded,
  );

  final String label;
  final String url;
  final IconData icon;
  const MapCartoStyle(this.label, this.url, this.icon);

  MapCartoStyle get next =>
      MapCartoStyle.values[(index + 1) % MapCartoStyle.values.length];
}

class MapBaseTileLayer extends StatelessWidget {
  const MapBaseTileLayer({super.key, required this.style});
  final MapCartoStyle style;

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      key: ValueKey(style.url),
      urlTemplate: style.url,
      userAgentPackageName: 'io.smartattendance.attendance',
      maxNativeZoom: 19,
    );
  }
}

class MapSonarCircleLayer extends StatelessWidget {
  const MapSonarCircleLayer({
    super.key,
    required this.point,
    required this.pulseAnimation,
    this.zoneRadiusMeters = 60,
  });

  final LatLng point;
  final Animation<double> pulseAnimation;
  final double zoneRadiusMeters;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, _) {
        final progress = pulseAnimation.value;
        final innerRadius = 20.0 + (progress * 35.0);
        final innerAlpha = (1.0 - progress) * 0.40;
        final outerRadius = 35.0 + (progress * 55.0);
        final outerAlpha = (1.0 - progress) * 0.25;

        return CircleLayer(
          circles: [
            CircleMarker(
              point: point,
              color: AppColors.primary.withValues(alpha: 0.12),
              borderColor: AppColors.primary.withValues(alpha: 0.75),
              borderStrokeWidth: 2.0,
              useRadiusInMeter: true,
              radius: zoneRadiusMeters,
            ),
            CircleMarker(
              point: point,
              color: AppColors.primary.withValues(alpha: innerAlpha * 0.55),
              borderColor: AppColors.primary.withValues(alpha: innerAlpha),
              borderStrokeWidth: 1.5,
              useRadiusInMeter: true,
              radius: innerRadius,
            ),
            CircleMarker(
              point: point,
              color:
                  AppColors.accentIndigo.withValues(alpha: outerAlpha * 0.45),
              borderColor: AppColors.accentIndigo.withValues(alpha: outerAlpha),
              borderStrokeWidth: 1.2,
              useRadiusInMeter: true,
              radius: outerRadius,
            ),
          ],
        );
      },
    );
  }
}

class MapUserLocationMarkerLayer extends StatelessWidget {
  const MapUserLocationMarkerLayer({
    super.key,
    required this.point,
    required this.hasFix,
    required this.pulseAnimation,
    this.onTap,
  });

  final LatLng point;
  final bool hasFix;
  final Animation<double> pulseAnimation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = hasFix ? AppColors.primary : AppColors.systemOrange;
    return MarkerLayer(
      markers: [
        Marker(
          point: point,
          width: 54,
          height: 54,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, _) {
                final scale = 1.0 + (pulseAnimation.value * 0.12);
                return Center(
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
