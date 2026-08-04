// lib/core/location/location_service.dart
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../logging/app_logger.dart';

/// Posición capturada al momento de una marca.
typedef CapturedLocation = ({double lat, double lng, String? dir});

/// Estado de la infraestructura de ubicación (servicio + permiso).
typedef LocationStatus = ({bool serviceEnabled, bool permissionGranted});

/// Servicio único de geolocalización para marcas de asistencia (manual y QR).
/// Retorna null cuando no hay servicio/permiso — el registro continúa sin
/// ubicación, nunca se bloquea ni se inventa una posición.
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

  /// Captura la posición actual con respuesta ultrarrápida.
  /// 1. Intenta obtener la última posición conocida (0ms).
  /// 2. Si no existe, obtiene la posición con precisión alta y timeout de 2s.
  Future<CapturedLocation?> capture({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      return await _capture().timeout(timeout);
    } catch (e) {
      AppLogger.warning('Location capture timeout/error: $e');
      return null;
    }
  }

  Future<CapturedLocation?> _capture() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.warning('Location service disabled');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }

    // 1. Intento ultrarrápido: última posición conocida en caché (0ms)
    Position? position = await Geolocator.getLastKnownPosition();

    // 2. Si no hay posición reciente, obtener posición actual en alta precisión (timeout 2s)
    position ??= await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 2),
      ),
    );

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
