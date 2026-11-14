// ============================================================================
// ARCHIVO: map_top_telemetry_bar.dart
// QUÉ HACE: Barra superior translúcida con estado satelital (precisión y velocidad)
//           y botón de conmutación de proveedor cartográfico (Calles, Dark, etc.).
// CÓMO FUNCIONA: Muestra píldora con indicador verde/ámbar de GPS nativo y estilo.
// POR QUÉ: Mantiene la modularidad estricta < 85 líneas bajo Clean Architecture.
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/location/weather_service.dart';
import 'map_carto_style.dart';

class MapTopTelemetryBar extends StatelessWidget {
  const MapTopTelemetryBar({
    super.key,
    required this.hasFix,
    required this.accuracyMeters,
    required this.speedKmh,
    required this.currentStyle,
    required this.onCycleStyle,
    this.trafficEnabled = false,
    this.onToggleTraffic,
    this.trafficInfo,
    this.weather,
    this.weatherRadarEnabled = false,
    this.onToggleWeatherRadar,
  });

  final bool hasFix;
  final int accuracyMeters;
  final int speedKmh;
  final MapCartoStyle currentStyle;
  final VoidCallback onCycleStyle;
  final bool trafficEnabled;
  final VoidCallback? onToggleTraffic;
  final String? trafficInfo;
  final RealtimeWeatherData? weather;
  final bool weatherRadarEnabled;
  final VoidCallback? onToggleWeatherRadar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 1. Telemetría GPS ──
          _GlassPill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: hasFix
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF9500),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  hasFix ? 'GPS ±$accuracyMeters m' : 'Buscando satélites…',
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ],
            ),
          ),

          // ── 2. Clima y Temperatura en Tiempo Real ──
          if (weather != null) ...[
            const SizedBox(width: 5),
            _GlassPill(
              color: weather!.isRaining
                  ? const Color(0xFF0284C7).withValues(alpha: 0.35)
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(weather!.iconEmoji, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 3),
                  Text(
                    '${weather!.temperatureC.toStringAsFixed(0)}°C',
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ],

          // ── 3. Toggle Flujo de Tráfico Vehicular ──
          if (onToggleTraffic != null) ...[
            const SizedBox(width: 5),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleTraffic,
              child: _GlassPill(
                color: trafficEnabled
                    ? const Color(0xFF34C759).withValues(alpha: 0.35)
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.traffic,
                        size: 12,
                        color: trafficEnabled
                            ? const Color(0xFF34C759)
                            : Colors.white70),
                    const SizedBox(width: 3),
                    Text(
                      'Tráfico',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: trafficEnabled
                              ? const Color(0xFF34C759)
                              : Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── 4. Toggle Radar Doppler de Lluvia y Precipitaciones ──
          if (onToggleWeatherRadar != null) ...[
            const SizedBox(width: 5),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleWeatherRadar,
              child: _GlassPill(
                color: weatherRadarEnabled
                    ? const Color(0xFF0284C7).withValues(alpha: 0.38)
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.cloud_rain_fill,
                        size: 12,
                        color: weatherRadarEnabled
                            ? const Color(0xFF38BDF8)
                            : Colors.white70),
                    const SizedBox(width: 3),
                    Text(
                      'Lluvia',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: weatherRadarEnabled
                              ? const Color(0xFF38BDF8)
                              : Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── 5. Selector de Estilo Cartográfico (Calles, Nocturno, Satélite, Topo) ──
          const SizedBox(width: 5),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCycleStyle,
            child: _GlassPill(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(currentStyle.icon, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    currentStyle.label,
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child, this.color});
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color ?? Colors.black.withValues(alpha: 0.50),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18), width: 0.8),
            ),
            child: child,
          ),
        ),
      );
}
