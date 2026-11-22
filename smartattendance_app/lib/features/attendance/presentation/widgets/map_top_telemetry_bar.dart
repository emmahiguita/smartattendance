// ============================================================================
// ARCHIVO: map_top_telemetry_bar.dart
// QUÉ HACE: Barra superior Liquid Glass clara/adaptativa con selector de
//           perspectiva (3D 60° / 35° / 2D), selector de planos cartográficos
//           (Calles, Satélite, Relieve, Nocturno), tráfico, lluvia y GPS.
// CÓMO FUNCIONA: En modo claro usa cristal blanco translúcido con texto azul
//                marino (#0F172A); en modo oscuro usa obsidiana con texto blanco.
// POR QUÉ: Diseño claro profesional sin chips ocultos fuera de pantalla (< 185 líneas).
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/location/weather_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'map_carto_style.dart';

class MapTopTelemetryBar extends StatelessWidget {
  const MapTopTelemetryBar({
    super.key,
    required this.hasFix,
    required this.accuracyMeters,
    required this.speedKmh,
    required this.currentStyle,
    required this.onCycleStyle,
    this.is3DMode = true,
    this.pitchLabel = '3D 60°',
    this.onToggle3D,
    this.trafficEnabled = false,
    this.onToggleTraffic,
    this.trafficInfo,
    this.weather,
    this.weatherRadarEnabled = false,
    this.onToggleWeatherRadar,
  });

  final bool hasFix, is3DMode, trafficEnabled, weatherRadarEnabled;
  final int accuracyMeters, speedKmh;
  final MapCartoStyle currentStyle;
  final VoidCallback onCycleStyle;
  final String pitchLabel;
  final VoidCallback? onToggle3D, onToggleTraffic, onToggleWeatherRadar;
  final String? trafficInfo;
  final RealtimeWeatherData? weather;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onToggle3D != null) ...[
            _InteractiveChip(
              isDark: isDark,
              active: is3DMode,
              activeColor: const Color(0xFF007782),
              icon: is3DMode ? CupertinoIcons.cube_fill : CupertinoIcons.view_2d,
              label: pitchLabel,
              onTap: onToggle3D!,
            ),
            const SizedBox(width: 6),
          ],
          _InteractiveChip(
            isDark: isDark,
            active: currentStyle != MapCartoStyle.streets,
            activeColor: const Color(0xFF0284C7),
            icon: currentStyle.icon,
            label: currentStyle.label,
            onTap: onCycleStyle,
          ),
          if (onToggleTraffic != null) ...[
            const SizedBox(width: 6),
            _InteractiveChip(
              isDark: isDark,
              active: trafficEnabled,
              activeColor: const Color(0xFF047857),
              icon: CupertinoIcons.car_detailed,
              label: 'Tráfico',
              onTap: onToggleTraffic!,
            ),
          ],
          if (onToggleWeatherRadar != null) ...[
            const SizedBox(width: 6),
            _InteractiveChip(
              isDark: isDark,
              active: weatherRadarEnabled,
              activeColor: const Color(0xFF0369A1),
              icon: CupertinoIcons.cloud_rain_fill,
              label: 'Lluvia',
              onTap: onToggleWeatherRadar!,
            ),
          ],
          const SizedBox(width: 6),
          _GlassPill(
            isDark: isDark,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: hasFix ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  hasFix ? 'GPS ±$accuracyMeters m' : 'GPS…',
                  style: TextStyle(
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveChip extends StatelessWidget {
  const _InteractiveChip({
    required this.isDark,
    required this.active,
    required this.activeColor,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool isDark, active;
  final Color activeColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: _GlassPill(
        isDark: isDark,
        color: active ? activeColor : null,
        borderColor: active ? Colors.white.withValues(alpha: 0.28) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.5, color: fg),
            const SizedBox(width: 4.5),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child, required this.isDark, this.color, this.borderColor});
  final Widget child;
  final bool isDark;
  final Color? color, borderColor;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
            decoration: BoxDecoration(
              color: color ?? (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.86) : Colors.white.withValues(alpha: 0.94)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor ?? (isDark ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.08)),
                width: 0.8,
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.07), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: child,
          ),
        ),
      );
}
