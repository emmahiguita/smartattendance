// ============================================================================
// ARCHIVO: map_telemetry_hud.dart
// QUÉ HACE: Panel HUD flotante Liquid Glass que coordina la barra superior de telemetría
//           y la tarjeta de geocerca táctica con clima y tráfico en tiempo real.
// CÓMO FUNCIONA: Enlaza MapTopTelemetryBar y MapGeofenceCard delegando la presentación.
// POR QUÉ: Diseño modular y limpio < 80 líneas cumpliendo Clean Architecture.
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/location/weather_service.dart';
import '../controllers/map_realtime_tracker.dart';
import 'map_carto_style.dart';
import 'map_geofence_card.dart';
import 'map_top_telemetry_bar.dart';

class MapTelemetryHud extends StatelessWidget {
  const MapTelemetryHud({
    super.key,
    required this.tracker,
    required this.currentStyle,
    required this.onCycleStyle,
    required this.isStrictAdmin,
    required this.onOpenZoneManager,
    required this.onSelectZoneModal,
    this.trafficEnabled = false,
    this.onToggleTraffic,
    this.trafficInfo,
    this.weather,
    this.weatherRadarEnabled = false,
    this.onToggleWeatherRadar,
  });

  final MapRealtimeTracker tracker;
  final MapCartoStyle currentStyle;
  final VoidCallback onCycleStyle;
  final bool isStrictAdmin;
  final VoidCallback onOpenZoneManager;
  final VoidCallback onSelectZoneModal;
  final bool trafficEnabled;
  final VoidCallback? onToggleTraffic;
  final String? trafficInfo;
  final RealtimeWeatherData? weather;
  final bool weatherRadarEnabled;
  final VoidCallback? onToggleWeatherRadar;

  @override
  Widget build(BuildContext context) {
    final pos = tracker.currentPosition;
    final accuracyM = pos?.accuracy.round() ?? 0;
    final speedKmh = pos != null ? (pos.speed * 3.6).round() : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MapTopTelemetryBar(
          hasFix: tracker.hasFix,
          accuracyMeters: accuracyM,
          speedKmh: speedKmh,
          currentStyle: currentStyle,
          onCycleStyle: onCycleStyle,
          trafficEnabled: trafficEnabled,
          onToggleTraffic: onToggleTraffic,
          trafficInfo: trafficInfo,
          weather: weather,
          weatherRadarEnabled: weatherRadarEnabled,
          onToggleWeatherRadar: onToggleWeatherRadar,
        ),
        const SizedBox(height: 8),
        MapGeofenceCard(
          tracker: tracker,
          isStrictAdmin: isStrictAdmin,
          onOpenZoneManager: onOpenZoneManager,
          onSelectZoneModal: onSelectZoneModal,
          trafficEnabled: trafficEnabled,
          weather: weather,
        ),
      ],
    );
  }
}
