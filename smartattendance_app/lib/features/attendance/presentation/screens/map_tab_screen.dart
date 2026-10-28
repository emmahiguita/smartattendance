// ============================================================================
// ARCHIVO: map_tab_screen.dart
// QUÉ HACE: Visor geoespacial 100% interactivo con adaptación automática a
//           Modo Oscuro (`MapCartoStyle.dark` CartoDB Dark Matter), HUD Liquid
//           Glass, ruta a Google Maps y telemetría en vivo hacia Traccar.
// CÓMO FUNCIONA:
// 1. Si el tema está en Modo Oscuro y el usuario no ha forzado otro estilo de
//    mapa, activa automáticamente las teselas nocturnas `MapCartoStyle.dark`.
// 2. Renderiza el panel de geocerca con `RepaintBoundary` + `BackdropFilter`
//    y reflejo especular cenital iOS 26.
// POR QUÉ: Cumple auditoría de mapas + Traccar + Modo Oscuro Avanzado (< 195 líneas).
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/location/traccar_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/zone_dialog.dart';
import '../widgets/map_hud_controls.dart';
import '../widgets/map_sonar_layer.dart';

class MapTabScreen extends ConsumerStatefulWidget {
  final double? latitude, longitude, zoneLat, zoneLng, zoneRadius;
  final String? zoneName, zoneAddress, userDocument;
  final VoidCallback? onRefresh;

  const MapTabScreen({
    super.key,
    this.latitude,
    this.longitude,
    this.zoneLat,
    this.zoneLng,
    this.zoneRadius,
    this.zoneName,
    this.zoneAddress,
    this.userDocument,
    this.onRefresh,
  });

  @override
  ConsumerState<MapTabScreen> createState() => _MapTabScreenState();
}

class _MapTabScreenState extends ConsumerState<MapTabScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _pulseController;
  MapCartoStyle? _manualStyle;
  String _traccarStatus = 'Traccar GPS listo';
  bool _syncingTraccar = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    _syncTraccarNow();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _zoomBy(double d) => _mapController.move(_mapController.camera.center, (_mapController.camera.zoom + d).clamp(3.0, 20.0));

  Future<void> _syncTraccarNow() async {
    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat == null || lng == null || _syncingTraccar) return;
    setState(() => _syncingTraccar = true);
    final res = await const TraccarService().pushPosition(
      deviceId: widget.userDocument ?? 'serviciudad-gps',
      latitude: lat,
      longitude: lng,
      zoneName: widget.zoneName,
    );
    if (mounted) setState(() { _syncingTraccar = false; _traccarStatus = res.statusText; });
  }

  Future<void> _openGoogleMaps(double destLat, double destLng) async {
    final intentUri = Uri.parse('google.navigation:q=$destLat,$destLng&mode=d');
    final webUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving');
    try {
      if (await canLaunchUrl(intentUri)) { await launchUrl(intentUri, mode: LaunchMode.externalApplication); return; }
    } catch (_) {}
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openZoneManager() async {
    final db = await ref.read(localPhotoDatabaseProvider).database;
    final rows = await db.query('work_zones', orderBy: 'id ASC', limit: 1);
    if (!mounted) return;
    final changed = await showDialog<bool>(context: context, builder: (_) => ZoneDialog(zone: rows.firstOrNull));
    if (changed == true) widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final effectiveStyle = _manualStyle ?? (isDark ? MapCartoStyle.dark : MapCartoStyle.streets);
    final isStrictAdmin = ref.watch(localActorProvider).isStrictAdmin;
    final lat = widget.latitude ?? 4.8333;
    final lng = widget.longitude ?? -75.6833;
    final userPt = LatLng(lat, lng);
    final hasFix = widget.latitude != null && widget.longitude != null;
    final hasZone = widget.zoneLat != null && widget.zoneLng != null;
    final zonePt = hasZone ? LatLng(widget.zoneLat!, widget.zoneLng!) : userPt;
    final radiusM = widget.zoneRadius ?? 80.0;
    final distM = hasZone && hasFix ? const Distance().as(LengthUnit.Meter, userPt, zonePt) : null;
    final inside = distM != null && distM <= radiusM;
    final distLabel = distM != null ? (distM >= 1000 ? '${(distM / 1000).toStringAsFixed(1)} km' : '${distM.round()} m') : 'Calculando';
    final badgeColor = inside ? (isDark ? AppColors.successDark : AppColors.success) : const Color(0xFFF59E0B);

    return Stack(children: [
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: userPt, initialZoom: 16.5, minZoom: 3.0, maxZoom: 20.0),
        children: [
          MapBaseTileLayer(style: effectiveStyle),
          if (hasZone && hasFix)
            PolylineLayer(polylines: [Polyline(points: [userPt, zonePt], strokeWidth: 3.0, color: inside ? badgeColor : context.cPrimary)]),
          MapSonarCircleLayer(point: zonePt, pulseAnimation: _pulseController, zoneRadiusMeters: radiusM, isInside: inside),
          MapUserLocationMarkerLayer(point: userPt, hasFix: hasFix, isInside: inside, pulseAnimation: _pulseController),
        ],
      ),
      Positioned(
        top: 12, left: 14, right: 14,
        child: MapTopHudBar(latitude: lat, longitude: lng, hasFix: hasFix, selectedStyle: effectiveStyle, onCycleStyle: () => setState(() => _manualStyle = effectiveStyle.next)),
      ),
      Positioned(
        top: 58, left: 14, right: 14,
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF07101E).withValues(alpha: 0.56) : context.cSurface.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.18) : context.cBorder.withValues(alpha: 0.65), width: 0.85),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Icon(inside ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.location_north_line_fill, size: 15, color: badgeColor),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${widget.zoneName ?? 'Sede Asignada'} • $distLabel', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: context.cTextPrimary))),
                    if (isStrictAdmin)
                      GestureDetector(onTap: _openZoneManager, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Icon(CupertinoIcons.pencil_circle_fill, size: 18, color: context.cPrimary))),
                    if (hasZone)
                      GestureDetector(
                        onTap: () => _openGoogleMaps(widget.zoneLat!, widget.zoneLng!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: context.cPrimary, borderRadius: BorderRadius.circular(8)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(CupertinoIcons.map_pin_ellipse, size: 12, color: Colors.white), SizedBox(width: 4), Text('Ruta', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white))]),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 3),
                  Text('Dirección: ${widget.zoneAddress ?? 'Dosquebradas, Risaralda'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: context.cTextSecondary)),
                  const SizedBox(height: 3),
                  GestureDetector(
                    onTap: _syncTraccarNow,
                    child: Row(children: [
                      const Icon(CupertinoIcons.antenna_radiowaves_left_right, size: 12, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 5),
                      Expanded(child: Text(_traccarStatus, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8)))),
                      Text('Sincronizar Traccar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: context.cPrimary)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 92, left: 14, right: 14,
        child: MapBottomHudBar(expandLabel: 'Ver geocerca', expandIcon: CupertinoIcons.scope, onExpand: () => _mapController.move(zonePt, 17.0), onZoomIn: () => _zoomBy(1.0), onZoomOut: () => _zoomBy(-1.0), onRecenter: () => _mapController.move(userPt, 17.0)),
      ),
    ]);
  }
}
