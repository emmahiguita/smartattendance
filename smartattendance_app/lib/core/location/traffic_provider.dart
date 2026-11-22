// ============================================================================
// ARCHIVO: traffic_provider.dart
// QUÉ HACE: Contrato e implementaciones desacopladas para tráfico en vivo en Colombia:
//           - `TrafficProvider`: interfaz abstracta (DIP / OCP) para proveedores.
//           - `TomTomTrafficProvider`: flujo y teselas transparentes de TomTom v4.
//           - `GoogleTrafficProvider`: capa integrada de tráfico Google Roads.
// CÓMO FUNCIONA: Genera URLs de teselas XYZ ({z}/{x}/{y}) y consulta métricas
//                de velocidad y congestión (`TrafficFlowInfo`) por tramo vial.
// POR QUÉ: Permite alternar entre TomTom y Google sin modificar el visor de mapa (< 190 líneas).
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Datos de telemetría y congestión vehicular para un punto geográfico específico.
class TrafficFlowInfo {
  final int currentSpeed;
  final int freeFlowSpeed;
  final int currentDelaySeconds;
  final bool roadClosure;
  final double confidence;

  const TrafficFlowInfo({
    required this.currentSpeed,
    required this.freeFlowSpeed,
    required this.currentDelaySeconds,
    this.roadClosure = false,
    this.confidence = 1.0,
  });

  /// Nivel humano de congestión para el HUD del mapa.
  String get congestionLabel {
    if (roadClosure) return 'Vía Cerrada';
    if (currentSpeed <= 0) return 'Detenido';
    final ratio = currentSpeed / (freeFlowSpeed > 0 ? freeFlowSpeed : 40);
    if (ratio >= 0.85) return 'Fluido ($currentSpeed km/h)';
    if (ratio >= 0.55) return 'Moderado ($currentSpeed km/h)';
    return 'Lento ($currentSpeed km/h)';
  }
}

/// Contrato abstracto para proveedores intercambiables de tráfico.
abstract class TrafficProvider {
  String get name;
  bool get hasTransparentOverlay;
  String? getFlowTileUrlTemplate();
  String? getIncidentTileUrlTemplate();
  Future<TrafficFlowInfo?> fetchPointFlow(double lat, double lng);
}

/// Proveedor TomTom Traffic (Flujo relativo transparente + incidentes).
class TomTomTrafficProvider implements TrafficProvider {
  TomTomTrafficProvider({String? apiKey}) : _customKey = apiKey;

  final String? _customKey;
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'tomtom_traffic_api_key_v1';
  static const defaultPublicDevKey = 'pGBt2F3zN4iZ1vE8mKq7Xy9rUoW5jA2c';

  Future<String> _resolveKey() async {
    if (_customKey != null && _customKey.trim().isNotEmpty) return _customKey.trim();
    final saved = await _storage.read(key: _storageKey);
    return (saved != null && saved.trim().isNotEmpty) ? saved.trim() : defaultPublicDevKey;
  }

  /// QUÉ HACE: Permite guardar una clave personalizada en SecureStorage.
  static Future<void> saveApiKey(String key) async {
    await _storage.write(key: _storageKey, value: key.trim());
  }

  @override
  String get name => 'TomTom Traffic Colombia';

  @override
  bool get hasTransparentOverlay => true;

  @override
  String? getFlowTileUrlTemplate() {
    return 'https://api.tomtom.com/traffic/map/4/tile/flow/relative/{z}/{x}/{y}.png?key={key}&thickness=10';
  }

  @override
  String? getIncidentTileUrlTemplate() {
    return 'https://api.tomtom.com/traffic/map/4/tile/incidents/s3/{z}/{x}/{y}.png?key={key}';
  }

  /// QUÉ HACE: Consulta la velocidad de tráfico real en el punto satelital del usuario.
  /// CÓMO: Valida primero una API key real (fail-fast sin peticiones 403 zombi),
  ///       invoca `flowSegmentData` de TomTom v4 y cierra el cliente `Dio` en `finally`.
  /// POR QUÉ: Evita fugas de sockets y gasto de red/batería cada 25 s si no hay key propia.
  @override
  Future<TrafficFlowInfo?> fetchPointFlow(double lat, double lng) async {
    final key = await _resolveKey();
    if (key.isEmpty || key == defaultPublicDevKey) return null;
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ));
    try {
      const url = 'https://api.tomtom.com/traffic/services/4/flowSegmentData/relative0/10/json';
      final res = await dio.get<Map<String, dynamic>>(
        url,
        queryParameters: {
          'point': '$lat,$lng',
          'key': key,
          'unit': 'KMPH',
        },
      );
      final data = res.data?['flowSegmentData'] as Map<String, dynamic>?;
      if (data == null) return null;

      final current = (data['currentSpeed'] as num?)?.toInt() ?? 0;
      final freeFlow = (data['freeFlowSpeed'] as num?)?.toInt() ?? 40;
      final delay = (data['currentDelay'] as num?)?.toInt() ?? 0;
      final closed = data['roadClosure'] == true;
      final conf = (data['confidence'] as num?)?.toDouble() ?? 1.0;

      return TrafficFlowInfo(
        currentSpeed: current,
        freeFlowSpeed: freeFlow,
        currentDelaySeconds: delay,
        roadClosure: closed,
        confidence: conf,
      );
    } catch (_) {
      return null;
    } finally {
      dio.close();
    }
  }
}

/// Proveedor Google Traffic (Capa de mosaicos directos con tráfico).
class GoogleTrafficProvider implements TrafficProvider {
  const GoogleTrafficProvider();

  @override
  String get name => 'Google Traffic Colombia';

  @override
  bool get hasTransparentOverlay => false;

  @override
  String? getFlowTileUrlTemplate() =>
      'https://mt{s}.google.com/vt/lyrs=m,traffic&x={x}&y={y}&z={z}';

  @override
  String? getIncidentTileUrlTemplate() => null;

  @override
  Future<TrafficFlowInfo?> fetchPointFlow(double lat, double lng) async => null;
}
