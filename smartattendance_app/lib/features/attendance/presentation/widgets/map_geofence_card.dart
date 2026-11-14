// ============================================================================
// ARCHIVO: map_geofence_card.dart
// QUÉ HACE: Tarjeta Liquid Glass con estado táctico de geocerca, telemetría
//           meteorológica en vivo (lluvia, temperatura), tráfico y Traccar.
// CÓMO FUNCIONA: Despliega nombre de sede, distancia, semáforo vehicular e
//                indicador de clima con reporte si hay precipitaciones activas.
// POR QUÉ: Extraído de MapTelemetryHud para cumplir la regla estricta < 200 líneas.
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/location/weather_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/map_realtime_tracker.dart';

class MapGeofenceCard extends StatelessWidget {
  const MapGeofenceCard({
    super.key,
    required this.tracker,
    required this.isStrictAdmin,
    required this.onOpenZoneManager,
    required this.onSelectZoneModal,
    this.trafficEnabled = false,
    this.weather,
  });

  final MapRealtimeTracker tracker;
  final bool isStrictAdmin;
  final VoidCallback onOpenZoneManager;
  final VoidCallback onSelectZoneModal;
  final bool trafficEnabled;
  final RealtimeWeatherData? weather;

  Future<void> _openNavigation(double lat, double lng) async {
    final intentUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    try {
      if (await canLaunchUrl(intentUri)) {
        await launchUrl(intentUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final zone = tracker.activeZone;
    final inside = tracker.isInsideZone;
    final distM = tracker.distanceToZone;
    final distLabel = distM != null
        ? (distM >= 1000 ? '${(distM / 1000).toStringAsFixed(1)} km' : '${distM.round()} m')
        : 'Buscando GPS';
    final badgeColor = inside ? (isDark ? AppColors.successDark : AppColors.success) : const Color(0xFFF59E0B);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF07101E).withValues(alpha: 0.60) : context.cSurface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.16) : context.cBorder.withValues(alpha: 0.70), width: 0.85),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(inside ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.location_north_line_fill, size: 16, color: badgeColor),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text('${zone?.name ?? 'Sede Principal'} • $distLabel',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.cTextPrimary)),
                  ),
                  if (tracker.zones.length > 1)
                    GestureDetector(
                      onTap: onSelectZoneModal,
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: context.cPrimary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.building_2_fill, size: 11, color: context.cPrimary),
                            const SizedBox(width: 3),
                            Text('Sedes (${tracker.zones.length})', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.cPrimary)),
                          ],
                        ),
                      ),
                    ),
                  if (isStrictAdmin)
                    GestureDetector(
                      onTap: onOpenZoneManager,
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: Icon(CupertinoIcons.pencil_circle_fill, size: 18, color: context.cPrimary)),
                    ),
                  if (zone != null)
                    GestureDetector(
                      onTap: () => _openNavigation(zone.latitude, zone.longitude),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF007AFF), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.location_north_fill, size: 11, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Ruta', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text('Sede: ${zone?.name ?? 'Principal'} • Radio: ${zone?.radius.round() ?? 80} m',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: context.cTextPrimary)),
              Text(
                inside ? '✅ DENTRO: Habilitado para picar asistencia' : '⚠️ FUERA DE SEDE: Acércate al perímetro para marcar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: badgeColor),
              ),
              if (weather != null) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(weather!.iconEmoji, style: const TextStyle(fontSize: 10)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${weather!.conditionText} • ${weather!.temperatureC.toStringAsFixed(1)}°C (Hum: ${weather!.humidityPercent}%, Viento: ${weather!.windSpeedKmh.round()} km/h)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9.2, fontWeight: FontWeight.w600, color: weather!.isRaining ? const Color(0xFF38BDF8) : context.cTextSecondary),
                      ),
                    ),
                  ],
                ),
              ],
              if (trafficEnabled) ...[
                const SizedBox(height: 3),
                const Row(
                  children: [
                    _DotPill(color: Color(0xFF34C759), text: 'Fluido'),
                    SizedBox(width: 7),
                    _DotPill(color: Color(0xFFFFCC00), text: 'Lento'),
                    SizedBox(width: 7),
                    _DotPill(color: Color(0xFFFF3B30), text: 'Trancón'),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              GestureDetector(
                onTap: tracker.syncTraccarManual,
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.antenna_radiowaves_left_right, size: 11, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(tracker.traccarStatus, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8))),
                    ),
                    Text(tracker.isSyncingTraccar ? 'Transmitiendo…' : 'Sincronizar Traccar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.cPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotPill extends StatelessWidget {
  const _DotPill({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
        ],
      );
}
