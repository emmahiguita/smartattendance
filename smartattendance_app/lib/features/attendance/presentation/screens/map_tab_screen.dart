// ============================================================================
// ARCHIVO: map_tab_screen.dart
// QUÉ HACE: Orquestador de navegación cartográfica multi-plano 3D/35°/2D
//           (MapLibre + OpenFreeMap gratis con edificios 3D, Satélite Híbrido,
//           Relieve Topográfico, Nocturno 3D y rutas viales OSRM).
// CÓMO FUNCIONA: Combina `MapRealtimeTracker` (GPS real), `OsrmRoutingService`
//                (rutas por calles) y `WeatherService` sobre `Map3DNavigationView`.
// POR QUÉ: Aplica SRP y DIP permitiendo ver todos los planos en 3D/2D (< 230 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/location/osrm_routing_service.dart';
import '../../../../core/location/traffic_provider.dart';
import '../../../../core/location/weather_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/zone_dialog.dart';
import '../controllers/map_realtime_tracker.dart';
import '../widgets/map_3d_navigation_view.dart';
import '../widgets/map_hud_controls.dart';
import '../widgets/map_sonar_layer.dart';
import '../widgets/map_telemetry_hud.dart';
import '../widgets/map_zone_picker_sheet.dart';

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

class _MapTabScreenState extends ConsumerState<MapTabScreen> {
  final Map3DControllerBridge _bridge3D = Map3DControllerBridge();
  final WeatherService _weatherService = WeatherService();
  final TomTomTrafficProvider _trafficProvider = TomTomTrafficProvider();
  final NavigationRoutingProvider _router = const OsrmRoutingService();

  late final MapRealtimeTracker _tracker;
  MapCartoStyle? _manualStyle;
  double _cameraPitch = 58.0;
  bool _trafficEnabled = true;
  bool _weatherRadarEnabled = false;
  bool _loadingRoute = false;
  TrafficFlowInfo? _trafficFlow;
  RealtimeWeatherData? _weatherData;
  RoadRouteResult? _activeRoute;
  String? _radarTileUrl;
  DateTime? _lastTrafficFetch, _lastWeatherFetch;

  String get _pitchLabel => _cameraPitch >= 50
      ? '3D 60°'
      : (_cameraPitch >= 20 ? 'Vista 35°' : 'Plano 2D');

  void _cyclePitch() => setState(() {
        _cameraPitch = _cameraPitch >= 50 ? 35.0 : (_cameraPitch >= 20 ? 0.0 : 58.0);
      });

  @override
  void initState() {
    super.initState();
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
      if (_trafficEnabled) _fetchTraffic(pos.latitude, pos.longitude);
      _fetchWeather(pos.latitude, pos.longitude);
    }
    setState(() {});
  }

  Future<void> _fetchWeather(double lat, double lng) async {
    final now = DateTime.now();
    if (_lastWeatherFetch != null && now.difference(_lastWeatherFetch!).inSeconds < 40) return;
    _lastWeatherFetch = now;
    final w = await _weatherService.fetchCurrentWeather(lat, lng);
    final r = await _weatherService.fetchLatestRadarTileUrl();
    if (mounted) setState(() { if (w != null) _weatherData = w; if (r != null) _radarTileUrl = r; });
  }

  Future<void> _fetchTraffic(double lat, double lng) async {
    final now = DateTime.now();
    if (_lastTrafficFetch != null && now.difference(_lastTrafficFetch!).inSeconds < 25) return;
    _lastTrafficFetch = now;
    final info = await _trafficProvider.fetchPointFlow(lat, lng);
    if (mounted && info != null) setState(() => _trafficFlow = info);
  }

  // QUÉ HACE: Traza la ruta vial real por calles vía OSRM e inclina cámara a 60°.
  Future<void> _computeRoadRoute(LatLng origin, LatLng destination) async {
    if (_loadingRoute) return;
    setState(() => _loadingRoute = true);
    final route = await _router.fetchDrivingRoute(origin: origin, destination: destination);
    if (!mounted) return;
    setState(() {
      _loadingRoute = false;
      _activeRoute = route;
    });
    if (route != null) {
      _bridge3D.flyTo?.call(origin, zoom: 16.8, pitch: _cameraPitch);
    }
  }

  Future<void> _openZoneManager() async {
    final db = await ref.read(localPhotoDatabaseProvider).database;
    final activeId = _tracker.activeZone?.id;
    final rows = activeId != null
        ? await db.query('work_zones', where: 'id = ?', whereArgs: [activeId], limit: 1)
        : await db.query('work_zones', orderBy: 'id ASC', limit: 1);
    if (!mounted) return;
    final changed = await showDialog<bool>(context: context, builder: (_) => ZoneDialog(zone: rows.firstOrNull));
    if (changed == true) {
      _activeRoute = null;
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
          setState(() => _activeRoute = null);
          _bridge3D.flyTo?.call(LatLng(z.latitude, z.longitude), zoom: 16.5, pitch: _cameraPitch);
        },
      );

  @override
  void dispose() {
    _tracker.removeListener(_handleTrackerUpdate);
    _tracker.dispose();
    _weatherService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final style = _manualStyle ?? (isDark ? MapCartoStyle.dark : MapCartoStyle.streets);
    final isStrictAdmin = ref.watch(localActorProvider).isStrictAdmin;
    final pos = _tracker.currentPosition;
    final userPt = LatLng(pos?.latitude ?? widget.latitude ?? 4.8333, pos?.longitude ?? widget.longitude ?? -75.6833);
    final activeZone = _tracker.activeZone;
    final zonePt = activeZone != null
        ? LatLng(activeZone.latitude, activeZone.longitude)
        : LatLng(widget.zoneLat ?? 4.8333, widget.zoneLng ?? -75.6833);
    final routePts = _activeRoute?.points ?? const <LatLng>[];
    final liveHeading = (pos != null && pos.speed >= 1.5) ? pos.heading : 0.0;

    return OrientationBuilder(
      builder: (context, orientation) {
        final isLandscape = orientation == Orientation.landscape;
        return Stack(children: [
          Map3DNavigationView(
            userPoint: userPt,
            zonePoint: zonePt,
            zones: _tracker.zones,
            activeZone: activeZone,
            hasFix: _tracker.hasFix,
            isInsideZone: _tracker.isInsideZone,
            followUser: _tracker.followUser,
            heading: liveHeading,
            isDark: isDark,
            cartoStyle: style,
            cameraPitch: _cameraPitch,
            trafficEnabled: _trafficEnabled,
            weatherRadarEnabled: _weatherRadarEnabled,
            radarTileUrl: _radarTileUrl,
            routePoints: routePts,
            bridge: _bridge3D,
          ),
          Positioned(
            top: 12,
            left: 14,
            right: isLandscape ? null : 14,
            width: isLandscape ? 280 : null,
            child: MapTelemetryHud(
              tracker: _tracker,
              currentStyle: style,
              is3DMode: _cameraPitch > 0,
              pitchLabel: _pitchLabel,
              onToggle3D: _cyclePitch,
              onCycleStyle: () => setState(() => _manualStyle = style.next),
              trafficEnabled: _trafficEnabled,
              onToggleTraffic: () => setState(() => _trafficEnabled = !_trafficEnabled),
              trafficInfo: _trafficFlow?.congestionLabel,
              weather: _weatherData,
              weatherRadarEnabled: _weatherRadarEnabled,
              onToggleWeatherRadar: () => setState(() => _weatherRadarEnabled = !_weatherRadarEnabled),
              isStrictAdmin: isStrictAdmin,
              onOpenZoneManager: _openZoneManager,
              onSelectZoneModal: _openZonePicker,
              activeRoute: _activeRoute,
              loadingRoute: _loadingRoute,
              onComputeRoute: activeZone == null ? null : () => _computeRoadRoute(userPt, zonePt),
            ),
          ),
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + (isLandscape ? 82 : 88),
            left: 14,
            right: 14,
            child: MapBottomHudBar(
              expandLabel: _tracker.followUser ? 'Siguiendo en vivo' : 'Foco libre',
              expandIcon: _tracker.followUser ? CupertinoIcons.location_north_fill : CupertinoIcons.location,
              isFollowing: _tracker.followUser,
              onExpand: _tracker.toggleFollowUser,
              onZoomIn: () => _bridge3D.zoomIn?.call(),
              onZoomOut: () => _bridge3D.zoomOut?.call(),
              onRecenter: () {
                _tracker.followUser = true;
                _bridge3D.flyTo?.call(userPt, zoom: 17.2, pitch: _cameraPitch, bearing: liveHeading);
                setState(() {});
              },
            ),
          ),
        ]);
      },
    );
  }
}
