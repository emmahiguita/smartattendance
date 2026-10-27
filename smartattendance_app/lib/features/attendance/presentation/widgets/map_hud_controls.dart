// ============================================================================
// ARCHIVO: map_hud_controls.dart
// QUÉ HACE: Controles superpuestos (HUD) con efecto Glassmorphism para el
//           visor cartográfico GPS y estado vacío sin spinner infinito.
// CÓMO FUNCIONA: Renderiza `MapTopHudBar` (coordenadas y estilo),
//                `MapBottomHudBar` (zoom, centrado y pantalla completa) y
//                `MapEmptySignalState` (reintento limpio cuando no hay señal).
// POR QUÉ: Cumple SRP (< 185 líneas) y elimina el bucle infinito de carga GPS.
// ============================================================================

import 'dart:ui';
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
  });

  final double latitude, longitude;
  final bool hasFix;
  final MapCartoStyle selectedStyle;
  final VoidCallback onCycleStyle;

  @override
  Widget build(BuildContext context) {
    final dotColor = hasFix ? AppColors.systemGreen : AppColors.systemOrange;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Flexible(
        child: _HudGlassPill(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hasFix ? '${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°' : 'Sin fijación GPS',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: onCycleStyle,
        child: _HudGlassPill(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(selectedStyle.icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(selectedStyle.label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ),
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
    this.expandIcon = Icons.fullscreen_rounded,
  });

  final VoidCallback onExpand, onZoomOut, onZoomIn, onRecenter;
  final String expandLabel;
  final IconData expandIcon;

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        GestureDetector(
          onTap: onExpand,
          child: _HudGlassPill(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(expandIcon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(expandLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _HudIconBtn(icon: Icons.remove_rounded, onTap: onZoomOut),
          const SizedBox(width: 6),
          _HudIconBtn(icon: Icons.add_rounded, onTap: onZoomIn),
          const SizedBox(width: 6),
          _HudIconBtn(icon: Icons.my_location_rounded, color: const Color(0xFF60A5FA), onTap: onRecenter),
        ]),
      ]);
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
                Text('Obteniendo señal GPS del dispositivo…', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.cTextSecondary)),
              ])
            : Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.location_disabled_rounded, size: 26, color: AppColors.systemOrange.withValues(alpha: 0.85)),
                const SizedBox(height: 6),
                Text('Señal GPS no disponible en este momento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.cTextPrimary)),
                if (onRetry != null)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 15),
                    label: const Text('Activar y reintentar GPS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
              ]),
      ),
    );
  }
}

class _HudGlassPill extends StatelessWidget {
  const _HudGlassPill({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 0.8),
            ),
            child: child,
          ),
        ),
      );
}

class _HudIconBtn extends StatelessWidget {
  const _HudIconBtn({required this.icon, required this.onTap, this.color = Colors.white});
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap, child: _HudGlassPill(child: Icon(icon, size: 15, color: color)));
}
