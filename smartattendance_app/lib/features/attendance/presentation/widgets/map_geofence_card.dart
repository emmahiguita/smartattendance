// ============================================================================
// ARCHIVO: map_geofence_card.dart
// QUÉ HACE: Tarjeta Liquid Glass profesional de geocerca GPS, sedes, ruta,
//           estado de marcación, clima real y leyenda de tráfico de alto contraste.
// CÓMO FUNCIONA: Delega píldoras e indicadores a `map_geofence_widgets.dart`,
//                elimina opciones zombi y usa colores WCAG AA claro/oscuro.
// POR QUÉ: Cumple estrictamente SRP (< 180 líneas) y cero acciones muertas.
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/design_system/aqua_gloss_button.dart';
import '../../../../core/location/osrm_routing_service.dart';
import '../../../../core/location/weather_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/map_realtime_tracker.dart';
import 'map_geofence_widgets.dart';

class MapGeofenceCard extends StatelessWidget {
  const MapGeofenceCard({
    super.key,
    required this.tracker,
    required this.isStrictAdmin,
    required this.onOpenZoneManager,
    required this.onSelectZoneModal,
    this.trafficEnabled = false,
    this.weather,
    this.activeRoute,
    this.loadingRoute = false,
    this.onComputeRoute,
  });

  final MapRealtimeTracker tracker;
  final bool isStrictAdmin, trafficEnabled, loadingRoute;
  final VoidCallback onOpenZoneManager, onSelectZoneModal;
  final RealtimeWeatherData? weather;
  final RoadRouteResult? activeRoute;
  final VoidCallback? onComputeRoute;

  Future<void> _openNavigation(double lat, double lng) async {
    final candidates = [
      Uri.parse('google.navigation:q=$lat,$lng&mode=d'),
      Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving'),
    ];
    for (final uri in candidates) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (_) {}
    }
    final webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final zone = tracker.activeZone;
    final inside = tracker.isInsideZone;
    final distM = tracker.distanceToZone;
    final distLabel = distM != null
        ? (distM >= 1000 ? 'a ${(distM / 1000).toStringAsFixed(1)} km' : 'a ${distM.round()} m')
        : 'calculando…';
    final statusColor = inside
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
        : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309));
    final statusBg = inside
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.45) : const Color(0xFFDCFCE7))
        : (isDark ? const Color(0xFF78350F).withValues(alpha: 0.42) : const Color(0xFFFEF3C7));

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF07101E).withValues(alpha: 0.78) : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.08),
              width: 0.85,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08), blurRadius: 14, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Icon(inside ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.location_solid, size: 16, color: statusColor),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(zone?.name ?? 'Sin sede seleccionada',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: context.cTextPrimary)),
                ),
                if (zone != null) ...[
                  const SizedBox(width: 8),
                  AquaGlossButton(
                    icon: CupertinoIcons.location_north_fill,
                    label: activeRoute != null ? 'Navegar' : 'Ruta',
                    compact: true,
                    isLoading: loadingRoute,
                    topColor: const Color(0xFF1A8CFF),
                    bottomColor: const Color(0xFF005ECB),
                    onPressed: activeRoute != null
                        ? () => _openNavigation(zone.latitude, zone.longitude)
                        : (onComputeRoute ?? () => _openNavigation(zone.latitude, zone.longitude)),
                  ),
                ],
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: Text(
                    activeRoute != null
                        ? 'Ruta: ${activeRoute!.durationLabel} · ${activeRoute!.distanceLabel}'
                        : 'Radio ${zone?.radius.round() ?? 80} m · $distLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: activeRoute != null
                          ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1))
                          : context.cTextSecondary,
                    ),
                  ),
                ),
                if (tracker.zones.length > 1)
                  MapMetaPill(icon: CupertinoIcons.building_2_fill, label: 'Sedes (${tracker.zones.length})', isDark: isDark, onTap: onSelectZoneModal),
                if (isStrictAdmin) ...[
                  const SizedBox(width: 6),
                  MapMetaPill(icon: CupertinoIcons.pencil, label: 'Editar', isDark: isDark, onTap: onOpenZoneManager),
                ],
              ]),
              const SizedBox(height: 7),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(9)),
                child: Row(children: [
                  Icon(inside ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.exclamationmark_triangle_fill, size: 13.5, color: statusColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      inside ? 'Dentro de sede · Habilitado para marcar asistencia' : 'Fuera de sede · Acércate al perímetro para marcar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ]),
              ),
              if (weather != null || trafficEnabled) ...[
                const SizedBox(height: 6),
                Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  if (trafficEnabled) ...[
                    MapTrafficDot(dotColor: const Color(0xFF16A34A), textColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D), text: 'Fluido'),
                    MapTrafficDot(dotColor: const Color(0xFFEAB308), textColor: isDark ? const Color(0xFFFDE047) : const Color(0xFF92400E), text: 'Lento'),
                    MapTrafficDot(dotColor: const Color(0xFFDC2626), textColor: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C), text: 'Trancón'),
                  ],
                  if (weather != null)
                    Text('${weather!.conditionText} · ${weather!.temperatureC.toStringAsFixed(0)}°C',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: context.cTextSecondary)),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
