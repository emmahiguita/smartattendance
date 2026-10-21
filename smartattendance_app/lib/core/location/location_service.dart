// lib/core/location/location_service.dart
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../logging/app_logger.dart';

/// Posición capturada al momento de una marca.
typedef CapturedLocation = ({double lat, double lng, String? dir});

/// Estado de la infraestructura de ubicación (servicio + permiso).
typedef LocationStatus = ({bool serviceEnabled, bool permissionGranted});

/// Servicio compartido. El mapa admite ausencia de señal; una nueva asistencia
/// exige una lectura válida mediante attendancePosition(). No rastrea en fondo.
final class LocationService {
  const LocationService();

  /// Estado REAL del servicio y el permiso — para pantallas de estado
  /// (Configuración) y para mensajes honestos de GPS en el Home.
  Future<LocationStatus> checkStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      return (serviceEnabled: serviceEnabled, permissionGranted: granted);
    } catch (e) {
      AppLogger.warning('Location status check failed: $e');
      return (serviceEnabled: false, permissionGranted: false);
    }
  }

  /// Vista del mapa: usa una lectura reciente o solicita otra. La dirección es
  /// opcional porque el GPS puede funcionar sin internet ni geocodificación.
  Future<CapturedLocation?> capture({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      return await _capture().timeout(timeout);
    } catch (e) {
      AppLogger.warning('Location capture timeout/error: $e');
      return null;
    }
  }

  /// Al guardar se pide otra lectura al proveedor nativo, sin reutilizar el
  /// estado del mapa. Sin señal no se declara una marca geolocalizada exitosa.
  Future<Position> attendancePosition() async {
    try {
      return await _position(fresh: true);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException(
          'No se obtuvo ubicación. Activa GPS, permite ubicación precisa y reintenta.');
    }
  }

  Future<Position> _position({bool fresh = false}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const FormatException('Activa la ubicación del dispositivo.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw const FormatException(
          'Permite la ubicación para guardar asistencia.');
    }

    Position? position = fresh ? null : await Geolocator.getLastKnownPosition();
    if (position != null && !_valid(position)) {
      position = null;
    }

    // La búsqueda satelital sin red puede tardar; espera acotada y asíncrona.
    position ??= await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: fresh ? 20 : 3),
      ),
    );
    if (position.isMocked) {
      throw const FormatException(
          'Desactiva la ubicación simulada de Android.');
    }
    if (!_valid(position)) {
      throw const FormatException(
          'Ubicación antigua o imprecisa. Acércate a un lugar con señal GPS y reintenta.');
    }
    return position;
  }

  /// Rechaza coordenadas inválidas y lecturas de más de dos minutos o con
  /// error estimado superior a 100 m. Esto no sustituye validar una geocerca.
  bool _valid(Position position) =>
      !position.isMocked &&
      position.latitude.isFinite &&
      position.latitude.abs() <= 90 &&
      position.longitude.isFinite &&
      position.longitude.abs() <= 180 &&
      position.accuracy.isFinite &&
      position.accuracy >= 0 &&
      position.accuracy <= 100 &&
      DateTime.now().difference(position.timestamp).abs() <=
          const Duration(minutes: 2);

  Future<CapturedLocation?> _capture() async {
    final position = await _position();
    String? dir;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 1));
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        dir = '${p.street ?? ''}, ${p.locality ?? ''}'.trim();
        if (dir.startsWith(',')) dir = dir.substring(1).trim();
        if (dir.isEmpty) dir = null;
      }
    } catch (e) {
      AppLogger.warning('Reverse geocoding failed/timeout: $e');
    }

    return (lat: position.latitude, lng: position.longitude, dir: dir);
  }
}
