// ============================================================================
// ARCHIVO: map_tab_screen.dart
// QUÉ HACE: Visor geoespacial satelital 100% en vivo con streaming GPS por
//           hardware, detección de geocercas multi-sede SQLite y telemetría iOS.
// CÓMO FUNCIONA: Se enlaza a `MapRealtimeTracker` para actualizar posición,
//                distancia, velocidad, precisión (±m) y rumbo satelital sin mocks.
// POR QUÉ: Reemplaza mapas estáticos con un sistema de geolocalización profesional
//          y seguro para asistencia y geocercas (< 195 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/zone_dialog.dart';
import '../controllers/map_realtime_tracker.dart';
import '../widgets/map_hud_controls.dart';
import '../widgets/map_sonar_layer.dart';
import '../widgets/map_telemetry_hud.dart';
import '../widgets/map_traffic_overlay.dart';
import '../widgets/map_weather_overlay.dart';
import '../widgets/map_zone_picker_sheet.dart';
import '../../../../core/location/traffic_provider.dart';
import '../../../../core/location/weather_service.dart';

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

class _MapTabScreenState extends ConsumerState<MapTabScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _pulseController;
  late final MapRealtimeTracker _tracker;
  MapCartoStyle? _manualStyle;
  bool _trafficEnabled = true;
  TrafficFlowInfo? _trafficFlow;
  DateTime? _lastTrafficFetch;
  final WeatherService _weatherService = WeatherService();
  RealtimeWeatherData? _weatherData;
  String? _radarTileUrl;
  bool _weatherRadarEnabled = true;
  DateTime? _lastWeatherFetch;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _tracker = MapRealtimeTracker(
      database: ref.read(localPhotoDatabaseProvider),
      userDocument: widget.userDocument,
    );
    _tracker.addListener(_handleTrackerUpdate);
    _tracker.start(
      fallbackLat: widget.latitude,
      fallbackLng: widget.longitude,
      preferredZoneName: widget.zoneName,
    );
    _fetchWeather(widget.latitude ?? 4.8333, widget.longitude ?? -75.6833);
  }

  void _handleTrackerUpdate() {
    if (!mounted) return;
    final pos = _tracker.currentPosition;
    if (pos != null) {
      if (_tracker.followUser) {
        _mapController.move(
            LatLng(pos.latitude, pos.longitude), _mapController.camera.zoom);
      }
      if (_trafficEnabled) _fetchTraffic(pos.latitude, pos.longitude);
      _fetchWeather(pos.latitude, pos.longitude);
    }
    setState(() {});
  }

  Future<void> _fetchWeather(double lat, double lng) async {
    final now = DateTime.now();
    if (_lastWeatherFetch != null &&
        now.difference(_lastWeatherFetch!).inSeconds < 40) {
      return;
    }
    _lastWeatherFetch = now;
    final w = await _weatherService.fetchCurrentWeather(lat, lng);
    final r = await _weatherService.fetchLatestRadarTileUrl();
    if (mounted) {
      setState(() {
        if (w != null) _weatherData = w;
        if (r != null) _radarTileUrl = r;
      });
    }
  }

  Future<void> _fetchTraffic(double lat, double lng) async {
    final now = DateTime.now();
    if (_lastTrafficFetch != null &&
        now.difference(_lastTrafficFetch!).inSeconds < 25) {
      return;
    }
    _lastTrafficFetch = now;
    final info = await TomTomTrafficProvider().fetchPointFlow(lat, lng);
    if (mounted && info != null) setState(() => _trafficFlow = info);
  }

  void _toggleTraffic() {
    setState(() => _trafficEnabled = !_trafficEnabled);
    if (_trafficEnabled) {
      final pos = _tracker.currentPosition;
      if (pos != null) _fetchTraffic(pos.latitude, pos.longitude);
    }
  }

  @override
  void dispose() {
    _tracker.removeListener(_handleTrackerUpdate);
    _tracker.dispose();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _zoomBy(double d) => _mapController.move(_mapController.camera.center,
      (_mapController.camera.zoom + d).clamp(3.0, 20.0));

  Future<void> _openZoneManager() async {
    final db = await ref.read(localPhotoDatabaseProvider).database;
    final rows = await db.query('work_zones', orderBy: 'id ASC', limit: 1);
    if (!mounted) return;
    final changed = await showDialog<bool>(context: context, builder: (_) => ZoneDialog(zone: rows.firstOrNull));
    if (changed == true) {
      _tracker.start(fallbackLat: widget.latitude, fallbackLng: widget.longitude, preferredZoneName: widget.zoneName);
      widget.onRefresh?.call();
    }
  }

  void _openZonePicker() => showMapZonePickerSheet(
        context: context,
        zones: _tracker.zones,
        activeZone: _tracker.activeZone,
        onZoneSelected: (z) {
          _tracker.selectZone(z);
          _mapController.move(LatLng(z.latitude, z.longitude), 16.5);
        },
      );

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final style =
        _manualStyle ?? (isDark ? MapCartoStyle.dark : MapCartoStyle.streets);
    final isStrictAdmin = ref.watch(localActorProvider).isStrictAdmin;
    final pos = _tracker.currentPosition;
    final userPt = LatLng(pos?.latitude ?? widget.latitude ?? 4.8333,
        pos?.longitude ?? widget.longitude ?? -75.6833);
    final activeZone = _tracker.activeZone;
    final zonePt = activeZone != null
        ? LatLng(activeZone.latitude, activeZone.longitude)
        : LatLng(widget.zoneLat ?? 4.8333, widget.zoneLng ?? -75.6833);
    final inside = _tracker.isInsideZone;

    // OrientationBuilder adapta la posición del HUD según orientación
    // PORTRAIT: HUD en la parte superior (top:14)
    // LANDSCAPE: HUD se mueve a la izquierda con ancho máximo 280px para no tapar el mapa
    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        return Stack(children: [
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: userPt, initialZoom: 16.5, minZoom: 3.0, maxZoom: 20.0),
        children: [
          MapBaseTileLayer(style: style),
          MapTrafficOverlay(enabled: _trafficEnabled),
          MapWeatherOverlay(enabled: _weatherRadarEnabled, radarTileUrl: _radarTileUrl),
          if (_tracker.hasFix && activeZone != null)
            PolylineLayer(polylines: [
              Polyline(points: [userPt, zonePt], strokeWidth: 2.8, color: inside ? AppColors.successDark : const Color(0xFF007AFF)),
            ]),
          for (final z in _tracker.zones.where((z) => z.id != activeZone?.id))
            CircleLayer(circles: [
              CircleMarker(
                point: LatLng(z.latitude, z.longitude),
                radius: z.radius,
                useRadiusInMeter: true,
                color: Colors.blue.withValues(alpha: 0.08),
                borderColor: const Color(0xFF007AFF).withValues(alpha: 0.45),
                borderStrokeWidth: 1.2,
              ),
            ]),
          MapSonarCircleLayer(
            point: zonePt,
            pulseAnimation: _pulseController,
            zoneRadiusMeters: activeZone?.radius ?? widget.zoneRadius ?? 80.0,
            isInside: inside,
            zoneName: activeZone?.name ?? widget.zoneName,
          ),
          MapUserLocationMarkerLayer(
            point: userPt,
            hasFix: _tracker.hasFix,
            accuracyMeters: pos?.accuracy ?? 0,
            heading: pos?.heading ?? 0,
            isInside: inside,
            pulseAnimation: _pulseController,
            userLabel: 'Tu ubicación',
            onTap: () => _mapController.move(userPt, 18.0),
          ),
        ],
      ),
      Positioned(
        top: 14,
        left: 14,
        right: isLandscape ? null : 14,
        width: isLandscape ? 280 : null,
        child: MapTelemetryHud(
          tracker: _tracker,
          currentStyle: style,
          onCycleStyle: () => setState(() => _manualStyle = style.next),
          trafficEnabled: _trafficEnabled,
          onToggleTraffic: _toggleTraffic,
          trafficInfo: _trafficFlow?.congestionLabel,
          weather: _weatherData,
          weatherRadarEnabled: _weatherRadarEnabled,
          onToggleWeatherRadar: () => setState(() => _weatherRadarEnabled = !_weatherRadarEnabled),
          isStrictAdmin: isStrictAdmin,
          onOpenZoneManager: _openZoneManager,
          onSelectZoneModal: _openZonePicker,
        ),
      ),
      Positioned(
        bottom: isLandscape ? 16 : 92,
        left: 14,
        right: 14,
        child: MapBottomHudBar(
          expandLabel: _tracker.followUser ? 'Siguiendo en vivo' : 'Foco libre',
          expandIcon: _tracker.followUser ? CupertinoIcons.location_north_fill : CupertinoIcons.location,
          isFollowing: _tracker.followUser,
          onExpand: _tracker.toggleFollowUser,
          onZoomIn: () => _zoomBy(1.0),
          onZoomOut: () => _zoomBy(-1.0),
          onRecenter: () {
            _tracker.followUser = true;
            _mapController.move(userPt, 17.5);
            setState(() {});
          },
        ),
      ),
    ]);
      }, // cierre OrientationBuilder builder
    ); // cierre OrientationBuilder
  }
}
