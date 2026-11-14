// ============================================================================
// ARCHIVO: map_sonar_layer.dart
// QUÉ HACE: Renderiza las capas de geocerca sonar y el marcador del colaborador
//           con disco de precisión GPS horizontal y flecha de rumbo satelital.
// CÓMO FUNCIONA: Usa `CircleMarker` con `useRadiusInMeter` y animación continua.
// POR QUÉ: Presenta telemetría geoespacial precisa y estética iOS (< 160 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
export 'map_carto_style.dart';

class MapSonarCircleLayer extends StatelessWidget {
  const MapSonarCircleLayer({
    super.key,
    required this.point,
    required this.pulseAnimation,
    this.zoneRadiusMeters = 80,
    this.isInside = false,
    this.zoneName,
  });

  final LatLng point;
  final Animation<double> pulseAnimation;
  final double zoneRadiusMeters;
  final bool isInside;
  final String? zoneName;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        isInside ? AppColors.successDark : const Color(0xFF0A84FF);
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
                  width: 160,
                  height: 60,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: baseColor,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(CupertinoIcons.building_2_fill,
                            size: 14, color: Colors.white),
                      ),
                      if (zoneName != null && zoneName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.24),
                                width: 0.7),
                          ),
                          child: Text(
                            '🏢 $zoneName • ${zoneRadiusMeters.toInt()}m',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ],
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
    this.accuracyMeters = 0,
    this.heading = 0,
    this.isInside = false,
    this.onTap,
    this.userLabel,
  });

  final LatLng point;
  final bool hasFix;
  final double accuracyMeters;
  final double heading;
  final bool isInside;
  final Animation<double> pulseAnimation;
  final VoidCallback? onTap;
  final String? userLabel;

  @override
  Widget build(BuildContext context) {
    final activeColor = !hasFix
        ? const Color(0xFFFF9500)
        : (isInside ? AppColors.successDark : const Color(0xFF007AFF));

    return Stack(
      children: [
        if (hasFix && accuracyMeters > 0)
          CircleLayer(
            circles: [
              CircleMarker(
                point: point,
                radius: accuracyMeters.clamp(5.0, 150.0),
                useRadiusInMeter: true,
                color: activeColor.withValues(alpha: 0.12),
                borderColor: activeColor.withValues(alpha: 0.35),
                borderStrokeWidth: 1.0,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 130,
              height: 56,
              child: GestureDetector(
                onTap: onTap,
                child: AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, _) {
                    final scale = 1.0 + (pulseAnimation.value * 0.08);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: activeColor.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 0.6),
                          ),
                          child: Text(
                            userLabel ?? 'Tu ubicación (±${accuracyMeters.toInt()}m)',
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: activeColor,
                              border:
                                  Border.all(color: Colors.white, width: 2.0),
                              boxShadow: [
                                BoxShadow(
                                    color: activeColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1),
                              ],
                            ),
                            child: (heading > 0 && heading <= 360)
                                ? Transform.rotate(
                                    angle: (heading * 3.1415926535) / 180,
                                    child: const Icon(
                                        CupertinoIcons.location_north_fill,
                                        size: 13,
                                        color: Colors.white),
                                  )
                                : const Icon(CupertinoIcons.location_fill,
                                    size: 13, color: Colors.white),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
