// ============================================================================
// ARCHIVO: map_hud_controls.dart
// QUÉ HACE: Controles superpuestos (HUD) con efecto Liquid Glass claro/adaptativo
//           para el visor cartográfico GPS y selector de planos 3D/2D.
// CÓMO FUNCIONA: Renderiza `MapTopHudBar` (perspectiva 3D/35°/2D, plano y tráfico),
//                `MapBottomHudBar` (zoom, centrado y seguimiento) y
//                `MapEmptySignalState` sin spinner infinito.
// POR QUÉ: Cumple SRP (< 190 líneas) y unifica el diseño claro profesional.
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'map_sonar_layer.dart';

class MapTopHudBar extends StatelessWidget {
  const MapTopHudBar({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.hasFix,
    required this.selectedStyle,
    required this.onCycleStyle,
    this.pitchLabel = '3D 60°',
    this.is3DActive = true,
    this.onTogglePitch,
    this.trafficEnabled = false,
    this.onToggleTraffic,
  });

  final double latitude, longitude;
  final bool hasFix, is3DActive, trafficEnabled;
  final MapCartoStyle selectedStyle;
  final String pitchLabel;
  final VoidCallback onCycleStyle;
  final VoidCallback? onTogglePitch, onToggleTraffic;

  Widget _chip({
    required IconData icon,
    required String label,
    required bool active,
    required Color activeColor,
    required bool isDark,
    required Color fg,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: _HudGlassPill(
          isDark: isDark,
          color: active ? activeColor : null,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 12.5, color: active ? Colors.white : fg),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: active ? Colors.white : fg)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final fg = isDark ? Colors.white : const Color(0xFF0F172A);
    final dotColor = hasFix ? const Color(0xFF16A34A) : AppColors.systemOrange;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(
        child: _HudGlassPill(
          isDark: isDark,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hasFix ? '${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°' : 'Sin GPS',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 6),
      Row(mainAxisSize: MainAxisSize.min, children: [
        if (onTogglePitch != null) ...[
          _chip(
              icon: is3DActive ? CupertinoIcons.cube_fill : CupertinoIcons.view_2d,
              label: pitchLabel,
              active: is3DActive,
              activeColor: const Color(0xFF007782),
              isDark: isDark,
              fg: fg,
              onTap: onTogglePitch!),
          const SizedBox(width: 6),
        ],
        _chip(
            icon: selectedStyle.icon,
            label: selectedStyle.label,
            active: selectedStyle != MapCartoStyle.streets,
            activeColor: const Color(0xFF0284C7),
            isDark: isDark,
            fg: fg,
            onTap: onCycleStyle),
        if (onToggleTraffic != null) ...[
          const SizedBox(width: 6),
          _chip(
              icon: CupertinoIcons.car_detailed,
              label: 'Tráfico',
              active: trafficEnabled,
              activeColor: const Color(0xFF047857),
              isDark: isDark,
              fg: fg,
              onTap: onToggleTraffic!),
        ],
      ]),
    ]);
  }
}

class MapBottomHudBar extends StatelessWidget {
  const MapBottomHudBar({
    super.key,
    required this.onExpand,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onRecenter,
    this.expandLabel = 'Ampliar mapa',
    this.expandIcon = CupertinoIcons.fullscreen,
    this.isFollowing = true,
  });

  final VoidCallback onExpand, onZoomOut, onZoomIn, onRecenter;
  final String expandLabel;
  final IconData expandIcon;
  final bool isFollowing;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final fg = isDark ? Colors.white : const Color(0xFF0F172A);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      GestureDetector(
        onTap: onExpand,
        child: _HudGlassPill(
          isDark: isDark,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(expandIcon, size: 13.5, color: isFollowing ? const Color(0xFF007782) : fg),
            const SizedBox(width: 5),
            Text(expandLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
          ]),
        ),
      ),
      Row(mainAxisSize: MainAxisSize.min, children: [
        _HudIconBtn(icon: CupertinoIcons.minus, isDark: isDark, color: fg, onTap: onZoomOut),
        const SizedBox(width: 6),
        _HudIconBtn(icon: CupertinoIcons.plus, isDark: isDark, color: fg, onTap: onZoomIn),
        const SizedBox(width: 6),
        _HudIconBtn(
          icon: isFollowing ? CupertinoIcons.location_fill : CupertinoIcons.location,
          isDark: isDark,
          color: isFollowing ? const Color(0xFF0284C7) : fg,
          onTap: onRecenter,
        ),
      ]),
    ]);
  }
}

class MapEmptySignalState extends StatelessWidget {
  const MapEmptySignalState({super.key, required this.height, required this.isLoading, this.onRetry});
  final double height;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.cBorder, width: 0.8),
      ),
      child: Center(
        child: isLoading
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary)),
                const SizedBox(height: 8),
                Text('Obteniendo señal GPS del dispositivo…',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.cTextSecondary)),
              ])
            : Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(CupertinoIcons.location_slash_fill, size: 26, color: AppColors.systemOrange.withValues(alpha: 0.85)),
                const SizedBox(height: 6),
                Text('Señal GPS no disponible en este momento',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.cTextPrimary)),
                if (onRetry != null)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(CupertinoIcons.refresh, size: 15),
                    label: const Text('Activar y reintentar GPS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
              ]),
      ),
    );
  }
}

class _HudGlassPill extends StatelessWidget {
  const _HudGlassPill({required this.child, required this.isDark, this.color});
  final Widget child;
  final bool isDark;
  final Color? color;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color ?? (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.86) : Colors.white.withValues(alpha: 0.94)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.08), width: 0.8),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: child,
          ),
        ),
      );
}

class _HudIconBtn extends StatelessWidget {
  const _HudIconBtn({required this.icon, required this.onTap, required this.isDark, required this.color});
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final Color color;

  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: _HudGlassPill(isDark: isDark, child: Icon(icon, size: 15, color: color)));
}
