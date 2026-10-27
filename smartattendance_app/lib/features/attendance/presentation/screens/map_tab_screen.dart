// ============================================================================
// ARCHIVO: map_tab_screen.dart
// QUÉ HACE: Pantalla de la pestaña "Mapa" con visor geoespacial en vivo,
//           conexión GPS real hacia la geocerca asignada y enlace a Google Maps.
// CÓMO FUNCIONA: Traza el vector de ruta entre la ubicación GPS real del equipo
//                y la zona asignada, permitiendo abrir navegación en Google Maps.
// POR QUÉ: Satisface la consulta: "¿Puede usar recursos de Google Maps reales
//          y conectar la ubicación con la zona cuando se le asigne la ruta?" (< 175 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/map_hud_controls.dart';
import '../widgets/map_sonar_layer.dart';

class MapTabScreen extends StatefulWidget {
  final double? latitude, longitude, zoneLat, zoneLng, zoneRadius;
  final String? zoneName;
  final VoidCallback? onRefresh;

  const MapTabScreen({
    super.key,
    this.latitude,
    this.longitude,
    this.zoneLat,
    this.zoneLng,
    this.zoneRadius,
    this.zoneName,
    this.onRefresh,
  });

  @override
  State<MapTabScreen> createState() => _MapTabScreenState();
}

class _MapTabScreenState extends State<MapTabScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _pulseController;
  MapCartoStyle _style = MapCartoStyle.streets;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
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

  void _recenter(LatLng point) => _mapController.move(point, 17.0);

  Future<void> _openGoogleMaps(double destLat, double destLng) async {
    final intentUri = Uri.parse('google.navigation:q=$destLat,$destLng&mode=d');
    final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving');
    try {
      if (await canLaunchUrl(intentUri)) {
        await launchUrl(intentUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.latitude ?? 4.8333;
    final lng = widget.longitude ?? -75.6833;
    final userPoint = LatLng(lat, lng);
    final hasFix = widget.latitude != null && widget.longitude != null;
    final hasZone = widget.zoneLat != null && widget.zoneLng != null;
    final zonePoint = hasZone ? LatLng(widget.zoneLat!, widget.zoneLng!) : userPoint;

    final distanceM = hasZone && hasFix ? const Distance().as(LengthUnit.Meter, userPoint, zonePoint) : null;
    final distLabel = distanceM != null ? (distanceM >= 1000 ? '${(distanceM / 1000).toStringAsFixed(1)} km' : '${distanceM.round()} m') : null;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: userPoint, initialZoom: 16.5, minZoom: 3.0, maxZoom: 20.0),
          children: [
            MapBaseTileLayer(style: _style),
            if (hasZone && hasFix)
              PolylineLayer(
                polylines: [
                  Polyline(points: [userPoint, zonePoint], strokeWidth: 2.8, color: AppColors.primary),
                ],
              ),
            MapSonarCircleLayer(point: zonePoint, pulseAnimation: _pulseController, zoneRadiusMeters: widget.zoneRadius ?? 80),
            MapUserLocationMarkerLayer(point: userPoint, hasFix: hasFix, pulseAnimation: _pulseController),
          ],
        ),
        Positioned(
          top: 14,
          left: 14,
          right: 14,
          child: MapTopHudBar(
            latitude: lat,
            longitude: lng,
            hasFix: hasFix,
            selectedStyle: _style,
            onCycleStyle: () => setState(() => _style = _style.next),
          ),
        ),
        Positioned(
          top: 70,
          left: 14,
          right: 14,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: context.cSurface.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.cBorder.withValues(alpha: 0.6), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.location_north_fill, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${widget.zoneName ?? 'Sede Principal'}${distLabel != null ? ' · $distLabel' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: context.cTextPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasZone) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _openGoogleMaps(widget.zoneLat!, widget.zoneLng!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.arrow_up_right_diamond_fill, size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Google Maps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          left: 14,
          right: 14,
          child: MapBottomHudBar(
            expandLabel: 'Centrar sede',
            expandIcon: CupertinoIcons.scope,
            onExpand: () => _recenter(zonePoint),
            onZoomIn: () => _zoomBy(1.0),
            onZoomOut: () => _zoomBy(-1.0),
            onRecenter: () => _recenter(userPoint),
          ),
        ),
      ],
    );
  }
}
