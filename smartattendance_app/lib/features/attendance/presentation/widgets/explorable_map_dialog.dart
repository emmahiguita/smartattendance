// ============================================================================
// ARCHIVO: explorable_map_dialog.dart
// QUÉ HACE: Modal de mapa interactivo a pantalla completa para explorar la
//           ubicación GPS en vivo y el perímetro de la geocerca autorizada.
// CÓMO FUNCIONA: Reutiliza `MapBaseTileLayer`, `MapSonarCircleLayer`,
//                `MapUserLocationMarkerLayer` y los controles HUD modulares.
// POR QUÉ: Reduce el archivo de 491 a < 165 líneas cumpliendo SRP y SOLID.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'map_hud_controls.dart';
import 'map_sonar_layer.dart';

class ExplorableMapDialog extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? zoneLat;
  final double? zoneLng;
  final double? zoneRadius;
  final String? zoneName;
  final MapCartoStyle initialStyle;

  const ExplorableMapDialog({
    super.key,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.zoneLat,
    this.zoneLng,
    this.zoneRadius,
    this.zoneName,
    this.initialStyle = MapCartoStyle.streets,
  });

  static Future<void> show(
    BuildContext context, {
    required double latitude,
    required double longitude,
    double? accuracy,
    double? zoneLat,
    double? zoneLng,
    double? zoneRadius,
    String? zoneName,
    MapCartoStyle initialStyle = MapCartoStyle.streets,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar mapa',
      barrierColor: Colors.black.withValues(alpha: 0.78),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim, secAnim) => ExplorableMapDialog(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        zoneLat: zoneLat,
        zoneLng: zoneLng,
        zoneRadius: zoneRadius,
        zoneName: zoneName,
        initialStyle: initialStyle,
      ),
    );
  }

  @override
  State<ExplorableMapDialog> createState() => _ExplorableMapDialogState();
}

class _ExplorableMapDialogState extends State<ExplorableMapDialog>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _pulseController;
  late MapCartoStyle _style;

  @override
  void initState() {
    super.initState();
    _style = widget.initialStyle;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _zoomBy(double delta) {
    final cam = _mapController.camera;
    _mapController.move(cam.center, (cam.zoom + delta).clamp(3.0, 20.0));
  }

  @override
  Widget build(BuildContext context) {
    final userPoint = LatLng(widget.latitude, widget.longitude);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: userPoint,
                    initialZoom: 17.5,
                    minZoom: 3.0,
                    maxZoom: 20.0,
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
                  top: 14,
                  left: 14,
                  right: 14,
                  child: MapTopHudBar(
                    latitude: widget.latitude,
                    longitude: widget.longitude,
                    hasFix: true,
                    selectedStyle: _style,
                    onCycleStyle: () => setState(() => _style = _style.next),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: MapBottomHudBar(
                    expandLabel: 'Cerrar mapa',
                    expandIcon: Icons.close_fullscreen_rounded,
                    onExpand: () => Navigator.of(context).pop(),
                    onZoomOut: () => _zoomBy(-1),
                    onZoomIn: () => _zoomBy(1),
                    onRecenter: () => _mapController.move(userPoint, 17.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
