// ============================================================================
// ARCHIVO: realtime_map_viewer.dart
// QUÉ HACE: Visor cartográfico embebido con posición GPS real, ondas de
//           geocerca, selector de estilo y ampliación a pantalla completa.
// CÓMO FUNCIONA: Si no hay señal GPS y `isLoading` es falso, detiene el
//                controlador de animación y muestra `MapEmptySignalState` con
//                botón de reintento, eliminando el spinner infinito.
// POR QUÉ: Cumple SRP (< 185 líneas) y corrige procesos zombi de animación.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'explorable_map_dialog.dart';
import 'map_hud_controls.dart';
import 'map_sonar_layer.dart';

class RealtimeMapViewer extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final bool hasFix;
  final bool isLoading;
  final double? zoneLat;
  final double? zoneLng;
  final double? zoneRadius;
  final String? zoneName;
  final VoidCallback? onRetry;

  const RealtimeMapViewer({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.hasFix,
    this.isLoading = false,
    this.zoneLat,
    this.zoneLng,
    this.zoneRadius,
    this.zoneName,
    this.onRetry,
  });

  @override
  State<RealtimeMapViewer> createState() => _RealtimeMapViewerState();
}

class _RealtimeMapViewerState extends State<RealtimeMapViewer>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _pulseController;
  MapCartoStyle _style = MapCartoStyle.streets;
  LatLng? _lastMovedPosition;

  bool get _hasValidCoords =>
      widget.hasFix && widget.latitude != null && widget.longitude != null;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _syncPulseState();
  }

  void _syncPulseState() {
    if (_hasValidCoords) {
      if (!_pulseController.isAnimating) _pulseController.repeat();
    } else {
      if (_pulseController.isAnimating) _pulseController.stop();
    }
  }

  @override
  void didUpdateWidget(covariant RealtimeMapViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulseState();
    if (_hasValidCoords) {
      final newPos = LatLng(widget.latitude!, widget.longitude!);
      if (_lastMovedPosition == null ||
          const Distance().as(LengthUnit.Meter, _lastMovedPosition!, newPos) >
              2.0) {
        _lastMovedPosition = newPos;
        try {
          _mapController.move(newPos, _mapController.camera.zoom);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _zoomBy(double delta) {
    try {
      final cam = _mapController.camera;
      _mapController.move(cam.center, (cam.zoom + delta).clamp(13.0, 19.5));
    } catch (_) {}
  }

  void _openFullScreen(BuildContext context) {
    if (!_hasValidCoords) return;
    ExplorableMapDialog.show(
      context,
      latitude: widget.latitude!,
      longitude: widget.longitude!,
      accuracy: widget.accuracy,
      zoneLat: widget.zoneLat,
      zoneLng: widget.zoneLng,
      zoneRadius: widget.zoneRadius,
      zoneName: widget.zoneName,
      initialStyle: _style,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasValidCoords) {
      return MapEmptySignalState(
        height: 175,
        isLoading: widget.isLoading,
        onRetry: widget.onRetry,
      );
    }

    final userPoint = LatLng(widget.latitude!, widget.longitude!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 192,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: userPoint,
                initialZoom: 17.2,
                minZoom: 13.0,
                maxZoom: 19.5,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                MapBaseTileLayer(style: _style),
                MapSonarCircleLayer(
                  point: userPoint,
                  pulseAnimation: _pulseController,
                  zoneRadiusMeters: widget.zoneRadius ?? 60,
                ),
                MapUserLocationMarkerLayer(
                  point: userPoint,
                  hasFix: true,
                  pulseAnimation: _pulseController,
                ),
              ],
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: MapTopHudBar(
                latitude: widget.latitude!,
                longitude: widget.longitude!,
                hasFix: true,
                selectedStyle: _style,
                onCycleStyle: () => setState(() => _style = _style.next),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: MapBottomHudBar(
                onExpand: () => _openFullScreen(context),
                onZoomOut: () => _zoomBy(-1),
                onZoomIn: () => _zoomBy(1),
                onRecenter: () => _mapController.move(userPoint, 17.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
