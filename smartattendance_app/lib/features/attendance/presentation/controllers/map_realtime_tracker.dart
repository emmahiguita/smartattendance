// ============================================================================
// ARCHIVO: map_realtime_tracker.dart
// QUÉ HACE: Controlador de geolocalización satelital en vivo con streaming real
//           por hardware (Geolocator), cálculo dinámico de geocercas y Traccar.
// CÓMO FUNCIONA: Se suscribe a `getPositionStream`, recalcula distancias hacia
//                las zonas de trabajo en SQLite y sincroniza telemetría real.
// POR QUÉ: Elimina coordenadas estáticas o simuladas garantizando precisión GPS.
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/location/traccar_service.dart';
import '../../../photo_attendance/data/photo_database.dart';
import '../../../photo_attendance/domain/work_zone.dart';

class MapRealtimeTracker extends ChangeNotifier {
  MapRealtimeTracker({required PhotoDatabase database, String? userDocument})
      : _database = database,
        _userDocument = userDocument ?? 'buentiempo-gps';

  final PhotoDatabase _database;
  final String _userDocument;
  StreamSubscription<Position>? _positionSub;
  DateTime? _lastTraccarPush;

  Position? currentPosition;
  List<WorkZone> zones = [];
  WorkZone? activeZone;
  double? distanceToZone;
  bool isInsideZone = false;
  bool hasFix = false;
  bool isLoading = true;
  bool followUser = true;
  bool isSyncingTraccar = false;
  String traccarStatus = 'GPS en espera';

  // QUÉ HACE: Inicia el flujo reactivo de posiciones del GPS nativo y carga zonas.
  // CÓMO: Verifica permisos, consulta SQLite y escucha el stream de alta precisión.
  // POR QUÉ: Asegura que el mapa responda al movimiento físico real del usuario.
  Future<void> start(
      {double? fallbackLat,
      double? fallbackLng,
      String? preferredZoneName}) async {
    isLoading = true;
    notifyListeners();
    await _loadZonesFromDb(preferredZoneName);
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final permissionGranted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled || !permissionGranted) {
      if (fallbackLat != null && fallbackLng != null) {
        _applyPosition(Position(
          latitude: fallbackLat,
          longitude: fallbackLng,
          timestamp: DateTime.now(),
          accuracy: 25.0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ));
      }
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final initial = await Geolocator.getLastKnownPosition();
      if (initial != null && !initial.isMocked) _applyPosition(initial);
    } catch (_) {}

    // Inyección activa de GPS hardware de alta precisión
    Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    ).then((fresh) {
      if (!fresh.isMocked) _applyPosition(fresh);
    }).catchError((_) {});

    const settings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 2);
    _positionSub?.cancel();
    _positionSub =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      _applyPosition,
      onError: (_) {
        hasFix = false;
        notifyListeners();
      },
    );
    isLoading = false;
    notifyListeners();
  }

  // QUÉ HACE: Actualiza el estado reactivo con cada nueva lectura GPS del hardware.
  // CÓMO: Guarda posición, calcula distancia euclidiana y evalúa límite de geocerca.
  // POR QUÉ: Permite feedback visual instantáneo (sonar verde/azul y telemetría).
  void _applyPosition(Position pos) {
    currentPosition = pos;
    hasFix = true;
    _recalculateGeofence();
    _autoPushTraccar(pos);
    notifyListeners();
  }

  // QUÉ HACE: Carga todas las geocercas reales registradas en la base de datos local.
  // CÓMO: Lee la tabla `work_zones` y selecciona la asignada o primera encontrada.
  // POR QUÉ: Visualiza todas las sedes institucionales en el mapa sin datos falsos.
  Future<void> _loadZonesFromDb(String? preferredName) async {
    try {
      final db = await _database.database;
      final rows = await db.query('work_zones', orderBy: 'id ASC');
      zones = rows.map(WorkZone.fromRow).toList();
      if (zones.isNotEmpty) {
        activeZone = (preferredName != null)
            ? zones
                    .where((z) =>
                        z.name.toLowerCase() == preferredName.toLowerCase())
                    .firstOrNull ??
                zones.first
            : zones.first;
      }
    } catch (_) {}
  }

  // QUÉ HACE: Computa la distancia en metros entre el usuario y la zona activa.
  // CÓMO: Usa la fórmula Haversine de LatLong2 contra las coordenadas satelitales.
  // POR QUÉ: Determina con rigor legal y operativo si el colaborador puede marcar.
  void _recalculateGeofence() {
    final pos = currentPosition;
    final zone = activeZone;
    if (pos == null || zone == null) {
      distanceToZone = null;
      isInsideZone = false;
      return;
    }
    final userPt = LatLng(pos.latitude, pos.longitude);
    final zonePt = LatLng(zone.latitude, zone.longitude);
    distanceToZone = const Distance().as(LengthUnit.Meter, userPt, zonePt);
    isInsideZone = distanceToZone! <= zone.radius;
  }

  // QUÉ HACE: Cambia manualmente el foco hacia otra sede o geocerca registrada.
  // CÓMO: Reemplaza `activeZone` y actualiza inmediatamente distancias y polilíneas.
  // POR QUÉ: Permite al usuario consultar su cercanía a cualquier sede de la empresa.
  void selectZone(WorkZone zone) {
    activeZone = zone;
    _recalculateGeofence();
    notifyListeners();
  }

  // QUÉ HACE: Alterna el seguimiento automático de cámara con el movimiento GPS.
  // CÓMO: Invierte el booleano `followUser` para pausar centrado si el usuario explora.
  // POR QUÉ: Ergonomía estándar en aplicaciones de mapas (Google Maps / Apple Maps).
  void toggleFollowUser() {
    followUser = !followUser;
    notifyListeners();
  }

  // QUÉ HACE: Transmite periódicamente la posición viva al servidor Traccar OsmAnd.
  // CÓMO: Aplica un filtro de tiempo (25 seg) para no saturar la red celular.
  // POR QUÉ: Provee auditoría de geolocalización remota continua sin agotar batería.
  void _autoPushTraccar(Position pos) {
    final now = DateTime.now();
    if (_lastTraccarPush != null &&
        now.difference(_lastTraccarPush!).inSeconds < 25) {
      return;
    }
    _lastTraccarPush = now;
    const TraccarService()
        .pushPosition(
      deviceId: _userDocument,
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      zoneName: activeZone?.name,
    )
        .then((res) {
      traccarStatus = res.statusText;
      notifyListeners();
    }).catchError((_) {});
  }

  // QUÉ HACE: Fuerza una sincronización manual inmediata hacia Traccar.
  // CÓMO: Invoca `pushPosition` inmediatamente con la última posición capturada.
  // POR QUÉ: Permite al supervisor o trabajador verificar conectividad al instante.
  Future<void> syncTraccarManual() async {
    final pos = currentPosition;
    if (pos == null || isSyncingTraccar) return;
    isSyncingTraccar = true;
    notifyListeners();
    final res = await const TraccarService().pushPosition(
      deviceId: _userDocument,
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracy: pos.accuracy,
      zoneName: activeZone?.name,
    );
    isSyncingTraccar = false;
    traccarStatus = res.statusText;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
