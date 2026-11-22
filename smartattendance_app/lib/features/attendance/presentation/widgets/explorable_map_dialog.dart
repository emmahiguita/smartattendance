// ============================================================================
// ARCHIVO: explorable_map_dialog.dart
// QUÉ HACE: Modal de mapa interactivo multi-plano 3D/35°/2D a pantalla completa
//           con edificios 3D, Satélite Híbrido, Relieve, Nocturno y tráfico.
// CÓMO FUNCIONA: Reutiliza `Map3DNavigationView` (MapLibre 3D + OpenFreeMap gratis)
//                con transición modal nativa iOS (`FadeTransition` + `ScaleTransition`)
//                sin `OverlayEntry` huérfanos, calculando distancia real a la sede.
// POR QUÉ: Garantiza experiencia multi-plano 100% estable al ampliar (< 180 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/work_zone.dart';
import 'map_3d_navigation_view.dart';
import 'map_hud_controls.dart';
import 'map_sonar_layer.dart';

class ExplorableMapDialog extends StatefulWidget {
  final double latitude, longitude;
  final double? accuracy, zoneLat, zoneLng, zoneRadius;
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
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar mapa',
      barrierColor: Colors.black.withValues(alpha: 0.78),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, _, __) => ExplorableMapDialog(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        zoneLat: zoneLat,
        zoneLng: zoneLng,
        zoneRadius: zoneRadius,
        zoneName: zoneName,
        initialStyle: initialStyle,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<ExplorableMapDialog> createState() => _ExplorableMapDialogState();
}

class _ExplorableMapDialogState extends State<ExplorableMapDialog> {
  final Map3DControllerBridge _bridge3D = Map3DControllerBridge();
  late MapCartoStyle _style;
  double _cameraPitch = 58.0;
  bool _trafficEnabled = true;

  String get _pitchLabel =>
      _cameraPitch >= 50 ? '3D 60°' : (_cameraPitch >= 20 ? '35°' : '2D');

  void _cyclePitch() => setState(() {
        _cameraPitch =
            _cameraPitch >= 50 ? 35.0 : (_cameraPitch >= 20 ? 0.0 : 58.0);
      });

  @override
  void initState() {
    super.initState();
    _style = widget.initialStyle;
  }

  @override
  Widget build(BuildContext context) {
    final userPoint = LatLng(widget.latitude, widget.longitude);
    final hasZone = widget.zoneLat != null && widget.zoneLng != null;
    final zonePoint =
        hasZone ? LatLng(widget.zoneLat!, widget.zoneLng!) : userPoint;
    final radiusM = widget.zoneRadius ?? 80.0;
    final distM =
        const Distance().as(LengthUnit.Meter, userPoint, zonePoint);
    final isInside = !hasZone || distM <= radiusM;
    final activeZone = WorkZone(
      0,
      widget.zoneName ?? 'Sede asignada',
      zonePoint.latitude,
      zonePoint.longitude,
      radiusM,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 0.9,
                ),
              ),
              child: Stack(
                children: [
                  Map3DNavigationView(
                    userPoint: userPoint,
                    zonePoint: zonePoint,
                    zones: [activeZone],
                    activeZone: activeZone,
                    hasFix: true,
                    isInsideZone: isInside,
                    followUser: true,
                    heading: 0,
                    isDark: context.isDark,
                    cartoStyle: _style,
                    cameraPitch: _cameraPitch,
                    trafficEnabled: _trafficEnabled,
                    weatherRadarEnabled: false,
                    bridge: _bridge3D,
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
                      pitchLabel: _pitchLabel,
                      is3DActive: _cameraPitch > 0,
                      onTogglePitch: _cyclePitch,
                      trafficEnabled: _trafficEnabled,
                      onToggleTraffic: () =>
                          setState(() => _trafficEnabled = !_trafficEnabled),
                      onCycleStyle: () => setState(() => _style = _style.next),
                    ),
                  ),
                  Positioned(
                    bottom: 14,
                    left: 14,
                    right: 14,
                    child: MapBottomHudBar(
                      expandLabel: 'Cerrar mapa',
                      expandIcon: CupertinoIcons.fullscreen_exit,
                      onExpand: () => Navigator.of(context).pop(),
                      onZoomOut: () => _bridge3D.zoomOut?.call(),
                      onZoomIn: () => _bridge3D.zoomIn?.call(),
                      onRecenter: () => _bridge3D.flyTo
                          ?.call(userPoint, zoom: 17.2, pitch: _cameraPitch),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
