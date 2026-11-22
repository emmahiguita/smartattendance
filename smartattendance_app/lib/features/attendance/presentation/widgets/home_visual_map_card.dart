// ============================================================================
// ARCHIVO: home_visual_map_card.dart
// QUÉ HACE: Visor de mapa miniatura en vivo (3D/35°/2D) en la pantalla Inicio
//           con geocerca sonar animada, tráfico vehicular y controles limpios.
// CÓMO FUNCIONA: Renderiza `FlutterMap` compacto (`118px`) con proyección 3D
//                animada y botones flotantes sin bordes que desorienten.
// POR QUÉ: Integra el mapa miniatura real en la vista principal (< 195 líneas).
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'explorable_map_dialog.dart';
import 'map_sonar_layer.dart';
import 'map_traffic_overlay.dart';

class HomeVisualMapCard extends StatefulWidget {
  const HomeVisualMapCard({
    super.key,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.zoneLat,
    this.zoneLng,
    this.zoneRadius,
    this.zoneName,
    this.isInsideZone,
    this.distanceMeters,
    this.onRefresh,
    this.mapHeight = 116.0,
  });

  final double? latitude, longitude, accuracy, zoneLat, zoneLng, zoneRadius, distanceMeters;
  final double mapHeight;
  final String? zoneName;
  final bool? isInsideZone;
  final VoidCallback? onRefresh;

  @override
  State<HomeVisualMapCard> createState() => _HomeVisualMapCardState();
}

class _HomeVisualMapCardState extends State<HomeVisualMapCard>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _pulseController;
  MapCartoStyle? _manualStyle;
  double _cameraPitch = 42.0;
  bool _trafficEnabled = true;

  String get _pitchLabel => _cameraPitch >= 40 ? '3D 60°' : (_cameraPitch >= 20 ? '35°' : '2D');

  void _cyclePitch() {
    HapticFeedback.selectionClick();
    setState(() => _cameraPitch = _cameraPitch >= 40 ? 24.0 : (_cameraPitch >= 20 ? 0.0 : 42.0));
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
  }

  @override
  void didUpdateWidget(covariant HomeVisualMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != null &&
        widget.longitude != null &&
        (oldWidget.latitude != widget.latitude || oldWidget.longitude != widget.longitude)) {
      final pt = LatLng(widget.latitude!, widget.longitude!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapController.move(pt, _mapController.camera.zoom);
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final style = _manualStyle ?? (isDark ? MapCartoStyle.dark : MapCartoStyle.streets);
    final userPt = widget.latitude != null && widget.longitude != null ? LatLng(widget.latitude!, widget.longitude!) : null;
    final zonePt = widget.zoneLat != null && widget.zoneLng != null ? LatLng(widget.zoneLat!, widget.zoneLng!) : null;
    final center = userPt ?? zonePt ?? const LatLng(4.8333, -75.6833);
    final fg = isDark ? Colors.white : const Color(0xFF0F172A);
    final subFg = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final distTxt = widget.distanceMeters != null
        ? (widget.distanceMeters! >= 1000 ? ' · ${(widget.distanceMeters! / 1000).toStringAsFixed(1)} km' : ' · ${widget.distanceMeters!.round()} m')
        : '';
    final stateText = userPt == null
        ? (zonePt != null ? 'Sede: ${widget.zoneName ?? 'Asignada'}' : 'Ubicación GPS en espera')
        : zonePt == null
            ? 'GPS activo · Sin geocerca asignada'
            : '${widget.isInsideZone == true ? 'Dentro' : 'Fuera'} de geocerca · ${widget.zoneName ?? 'Sede'}$distTxt';

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ubicación y Geocerca en Vivo',
                    style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: fg)),
                Text(stateText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500, color: subFg)),
              ]),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: widget.onRefresh,
              icon: Icon(CupertinoIcons.refresh, size: 16, color: fg),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: Icon(CupertinoIcons.fullscreen, size: 16, color: fg),
              onPressed: () => ExplorableMapDialog.show(
                context,
                latitude: center.latitude,
                longitude: center.longitude,
                accuracy: widget.accuracy,
                zoneLat: widget.zoneLat,
                zoneLng: widget.zoneLng,
                zoneRadius: widget.zoneRadius,
                zoneName: widget.zoneName,
                initialStyle: style,
              ),
            ),
          ]),
          const SizedBox(height: 4),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : const Color(0xFF0F172A)).withValues(alpha: isDark ? 0.45 : 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: widget.mapHeight,
                child: Stack(fit: StackFit.expand, children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: _cameraPitch),
                    duration: const Duration(milliseconds: 340),
                    curve: Curves.easeOutCubic,
                    builder: (context, pitch, mapChild) {
                      final rad = (pitch * math.pi / 180.0) * 0.55;
                      final s = 1.0 + (pitch / 42.0) * 0.14;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..setEntry(3, 2, 0.0009)..rotateX(-rad)..scaleByDouble(s, s, 1.0, 1.0),
                        child: mapChild,
                      );
                    },
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(initialCenter: center, initialZoom: 16.5, minZoom: 4.0, maxZoom: 20.0),
                      children: [
                        MapBaseTileLayer(style: style),
                        MapTrafficOverlay(enabled: _trafficEnabled),
                        if (userPt != null && zonePt != null)
                          PolylineLayer(polylines: [
                            Polyline(
                              points: [userPt, zonePt],
                              strokeWidth: 2.6,
                              color: widget.isInsideZone == true ? AppColors.successDark : const Color(0xFF007AFF),
                            ),
                          ]),
                        if (zonePt != null)
                          MapSonarCircleLayer(
                            point: zonePt,
                            pulseAnimation: _pulseController,
                            zoneRadiusMeters: widget.zoneRadius ?? 80.0,
                            isInside: widget.isInsideZone == true,
                            zoneName: widget.zoneName,
                          ),
                        if (userPt != null)
                          MapUserLocationMarkerLayer(
                            point: userPt,
                            hasFix: true,
                            accuracyMeters: widget.accuracy ?? 12.0,
                            isInside: widget.isInsideZone == true,
                            pulseAnimation: _pulseController,
                            userLabel: 'Tu ubicación',
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    right: 6,
                    child: Row(children: [
                      _MiniPlaneBtn(
                        label: _pitchLabel,
                        icon: _cameraPitch > 0 ? CupertinoIcons.cube_fill : CupertinoIcons.view_2d,
                        active: _cameraPitch > 0,
                        activeColor: const Color(0xFF007782),
                        isDark: isDark,
                        onTap: _cyclePitch,
                      ),
                      const SizedBox(width: 5),
                      _MiniPlaneBtn(
                        label: style.label,
                        icon: style.icon,
                        active: style != MapCartoStyle.streets,
                        activeColor: const Color(0xFF0284C7),
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _manualStyle = style.next);
                        },
                      ),
                      const SizedBox(width: 5),
                      _MiniPlaneBtn(
                        label: 'Tráfico',
                        icon: CupertinoIcons.car_detailed,
                        active: _trafficEnabled,
                        activeColor: const Color(0xFF047857),
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _trafficEnabled = !_trafficEnabled);
                        },
                      ),
                      const Spacer(),
                      _MiniPlaneBtn(
                        label: 'Centrar',
                        icon: CupertinoIcons.location_fill,
                        active: false,
                        activeColor: const Color(0xFF007AFF),
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          try {
                            _mapController.move(center, 16.6);
                          } catch (_) {}
                        },
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPlaneBtn extends StatelessWidget {
  const _MiniPlaneBtn({required this.label, required this.icon, required this.active, required this.activeColor, required this.isDark, required this.onTap});
  final String label;
  final IconData icon;
  final bool active, isDark;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? activeColor : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.88) : Colors.white.withValues(alpha: 0.94)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11.5, color: fg),
          const SizedBox(width: 3.5),
          Text(label, style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w700, color: fg)),
        ]),
      ),
    );
  }
}
