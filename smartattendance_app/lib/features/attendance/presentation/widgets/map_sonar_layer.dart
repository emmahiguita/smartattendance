// ============================================================================
// ARCHIVO: map_sonar_layer.dart
// QUÉ HACE: Define los estilos cartográficos (`MapCartoStyle` incluyendo
//           `dark` CartoDB Dark Matter para Modo Oscuro iOS) y las capas
//           semánticas del mapa: geocerca sonar y marcador en vivo del trabajador.
// CÓMO FUNCIONA:
// 1. Geocerca Asignada: Círculo y ondas en Azul iOS (`#0A84FF`) o Verde
//    Esmeralda (`#10B981`) cuando el colaborador está dentro del perímetro.
// 2. Colaborador GPS: Pin circular animado en Verde si está en zona, Azul en
//    tránsito o Ámbar sin fijación GPS.
// POR QUÉ: Soporta Modo Oscuro cartográfico nativo y mantiene < 185 líneas.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';

enum MapCartoStyle {
  streets('Calles', 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', Icons.map_rounded),
  dark('Nocturno', 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png', Icons.dark_mode_rounded),
  satellite('Satélite', 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', Icons.satellite_alt_rounded),
  topo('Topográfico', 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}', Icons.terrain_rounded);

  final String label;
  final String url;
  final IconData icon;
  const MapCartoStyle(this.label, this.url, this.icon);

  MapCartoStyle get next => MapCartoStyle.values[(index + 1) % MapCartoStyle.values.length];
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
    this.zoneRadiusMeters = 80,
    this.isInside = false,
  });

  final LatLng point;
  final Animation<double> pulseAnimation;
  final double zoneRadiusMeters;
  final bool isInside;

  @override
  Widget build(BuildContext context) {
    final baseColor = isInside ? AppColors.successDark : AppColors.primaryDark;
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, _) {
        final progress = pulseAnimation.value;
        final innerRadius = 20.0 + (progress * 35.0);
        final innerAlpha = (1.0 - progress) * 0.40;
        final outerRadius = 35.0 + (progress * 55.0);
        final outerAlpha = (1.0 - progress) * 0.25;

        return Stack(
          children: [
            CircleLayer(
              circles: [
                CircleMarker(
                  point: point,
                  color: baseColor.withValues(alpha: 0.16),
                  borderColor: baseColor.withValues(alpha: 0.88),
                  borderStrokeWidth: 2.2,
                  useRadiusInMeter: true,
                  radius: zoneRadiusMeters,
                ),
                CircleMarker(
                  point: point,
                  color: baseColor.withValues(alpha: innerAlpha * 0.55),
                  borderColor: baseColor.withValues(alpha: innerAlpha),
                  borderStrokeWidth: 1.5,
                  useRadiusInMeter: true,
                  radius: innerRadius,
                ),
                CircleMarker(
                  point: point,
                  color: AppColors.accent.withValues(alpha: outerAlpha * 0.45),
                  borderColor: AppColors.accent.withValues(alpha: outerAlpha),
                  borderStrokeWidth: 1.2,
                  useRadiusInMeter: true,
                  radius: outerRadius,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 34,
                  height: 34,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryDark,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.business_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ],
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
    this.isInside = false,
    this.onTap,
  });

  final LatLng point;
  final bool hasFix;
  final bool isInside;
  final Animation<double> pulseAnimation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = !hasFix
        ? AppColors.systemOrange
        : (isInside ? AppColors.successDark : const Color(0xFF0EA5E9));
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
                      child: const Icon(Icons.my_location_rounded, size: 16, color: Colors.white),
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
