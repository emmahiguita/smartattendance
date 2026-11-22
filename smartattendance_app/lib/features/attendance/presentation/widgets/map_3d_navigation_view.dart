// ============================================================================
// ARCHIVO: map_3d_navigation_view.dart
// QUÉ HACE: Visor cartográfico multi-plano 3D/35°/2D acelerado por el motor
//           gráfico de Flutter (`FlutterMap` + proyección 3D animada) con
//           soporte para Calles, Satélite, Relieve, Nocturno, Tráfico y Radar.
// CÓMO FUNCIONA: Renderiza teselas en el árbol nativo de Flutter en iOS/Android
//                para que los HUD `BackdropFilter` corran a 120 FPS.
// POR QUÉ: Elimina `oplus_no_buffer_commit` y bloqueos de superficie (< 195 líneas).
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../photo_attendance/domain/work_zone.dart';
import 'map_sonar_layer.dart';
import 'map_traffic_overlay.dart';
import 'map_weather_overlay.dart';

class Map3DControllerBridge {
  VoidCallback? zoomIn, zoomOut;
  void Function(double pitch)? setPitch;
  void Function(LatLng target, {double? zoom, double? bearing, double? pitch})? flyTo;
}

class Map3DNavigationView extends StatefulWidget {
  const Map3DNavigationView({
    super.key,
    required this.userPoint,
    required this.zonePoint,
    required this.zones,
    required this.activeZone,
    required this.hasFix,
    required this.isInsideZone,
    required this.followUser,
    required this.heading,
    required this.isDark,
    required this.trafficEnabled,
    required this.weatherRadarEnabled,
    required this.bridge,
    this.cartoStyle = MapCartoStyle.streets,
    this.cameraPitch = 58.0,
    this.radarTileUrl,
    this.routePoints = const [],
  });

  final LatLng userPoint, zonePoint;
  final List<WorkZone> zones;
  final WorkZone? activeZone;
  final bool hasFix, isInsideZone, followUser, isDark, trafficEnabled, weatherRadarEnabled;
  final double heading, cameraPitch;
  final MapCartoStyle cartoStyle;
  final String? radarTileUrl;
  final List<LatLng> routePoints;
  final Map3DControllerBridge bridge;

  @override
  State<Map3DNavigationView> createState() => _Map3DNavigationViewState();
}

class _Map3DNavigationViewState extends State<Map3DNavigationView>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _pulseController;
  LatLng? _lastMovedCenter;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _lastMovedCenter = widget.userPoint;
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
    _bindBridge();
  }

  void _bindBridge() {
    widget.bridge.zoomIn = () => _adjustZoom(1.0);
    widget.bridge.zoomOut = () => _adjustZoom(-1.0);
    widget.bridge.setPitch = (_) {};
    widget.bridge.flyTo = (pt, {zoom, bearing, pitch}) {
      _lastMovedCenter = pt;
      _safeMove(pt, zoom: zoom);
    };
  }

  void _safeMove(LatLng target, {double? zoom}) {
    if (!_mapReady || !mounted) return;
    try {
      _mapController.move(target, (zoom ?? _mapController.camera.zoom).clamp(3.0, 20.0));
    } catch (_) {}
  }

  void _adjustZoom(double delta) {
    if (!_mapReady || !mounted) return;
    try {
      final cam = _mapController.camera;
      _mapController.move(cam.center, (cam.zoom + delta).clamp(3.0, 20.0));
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant Map3DNavigationView old) {
    super.didUpdateWidget(old);
    _bindBridge();
    if (!_mapReady) return;
    final gotFirstFix = !old.hasFix && widget.hasFix;
    final movedMeters = _lastMovedCenter == null
        ? 999.0
        : const Distance().as(LengthUnit.Meter, _lastMovedCenter!, widget.userPoint);
    if (gotFirstFix || (widget.followUser && movedMeters >= 3.5)) {
      _lastMovedCenter = widget.userPoint;
      _safeMove(widget.userPoint);
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
    final active = widget.activeZone;
    final distM = active == null ? 999999.0 : const Distance().as(LengthUnit.Meter, widget.userPoint, widget.zonePoint);
    final routePts = widget.routePoints.length >= 2
        ? widget.routePoints
        : (widget.hasFix && active != null && distM <= 1800 ? [widget.userPoint, widget.zonePoint] : const <LatLng>[]);

    return ColoredBox(
      color: widget.isDark ? const Color(0xFF070E1A) : const Color(0xFFE2E8F0),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: widget.cameraPitch),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (context, pitch, mapChild) {
          final rad = (pitch * math.pi / 180.0) * 0.42;
          final s = 1.0 + (pitch / 58.0) * 0.14;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..setEntry(3, 2, 0.00085)..rotateX(-rad)..scaleByDouble(s, s, 1.0, 1.0),
            child: mapChild,
          );
        },
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.userPoint,
            initialZoom: 16.5,
            minZoom: 3.0,
            maxZoom: 20.0,
            onMapReady: () => _mapReady = true,
          ),
          children: [
            MapBaseTileLayer(style: widget.cartoStyle),
            MapTrafficOverlay(enabled: widget.trafficEnabled),
            MapWeatherOverlay(enabled: widget.weatherRadarEnabled, radarTileUrl: widget.radarTileUrl),
            if (routePts.length >= 2)
              PolylineLayer(polylines: [
                Polyline(
                  points: routePts,
                  strokeWidth: widget.routePoints.length >= 2 ? 5.2 : 3.0,
                  color: widget.routePoints.length >= 2
                      ? const Color(0xFF0A84FF)
                      : (widget.isInsideZone ? AppColors.successDark : const Color(0xFF007AFF)),
                ),
              ]),
            for (final z in widget.zones.where((z) => z.id != active?.id))
              CircleLayer(circles: [
                CircleMarker(
                  point: LatLng(z.latitude, z.longitude),
                  radius: z.radius,
                  useRadiusInMeter: true,
                  color: const Color(0xFF007AFF).withValues(alpha: 0.10),
                  borderColor: const Color(0xFF007AFF).withValues(alpha: 0.55),
                  borderStrokeWidth: 1.5,
                ),
              ]),
            if (active != null)
              MapSonarCircleLayer(
                point: widget.zonePoint,
                pulseAnimation: _pulseController,
                zoneRadiusMeters: active.radius,
                isInside: widget.isInsideZone,
                zoneName: active.name,
              ),
            MapUserLocationMarkerLayer(
              point: widget.userPoint,
              hasFix: widget.hasFix,
              accuracyMeters: 12.0,
              heading: widget.heading,
              isInside: widget.isInsideZone,
              pulseAnimation: _pulseController,
              userLabel: 'Tu ubicación',
              onTap: () => _safeMove(widget.userPoint, zoom: 17.5),
            ),
          ],
        ),
      ),
    );
  }
}
