// ============================================================================
// ARCHIVO: weather_service.dart
// QUÉ HACE: Servicio de telemetría meteorológica y radar Doppler de lluvia en tiempo real
//           para Pereira, Dosquebradas y toda Colombia (Open-Meteo + RainViewer).
// CÓMO FUNCIONA: Consulta las APIs satelitales y de radar meteorológico en tiempo real:
//                1. Open-Meteo: Temperatura (°C), humedad (%), lluvia (mm/h), viento y código WMO.
//                2. RainViewer: Teselas raster Doppler de precipitación en vivo para `FlutterMap`.
// POR QUÉ: Permite saber si está lloviendo en la sede operativa y desplegar el radar
//          de precipitaciones sobre el mapa sin requerir API keys de pago (< 190 líneas).
// ============================================================================

import 'dart:convert';
import 'package:dio/dio.dart';

class RealtimeWeatherData {
  const RealtimeWeatherData({
    required this.temperatureC,
    required this.humidityPercent,
    required this.precipitationMm,
    required this.rainMm,
    required this.weatherCode,
    required this.windSpeedKmh,
    required this.updatedAt,
  });

  final double temperatureC;
  final int humidityPercent;
  final double precipitationMm;
  final double rainMm;
  final int weatherCode;
  final double windSpeedKmh;
  final DateTime updatedAt;

  // QUÉ HACE: Determina si actualmente se registran precipitaciones en las coordenadas.
  bool get isRaining =>
      precipitationMm > 0.05 ||
      rainMm > 0.05 ||
      (weatherCode >= 51 && weatherCode <= 67) ||
      (weatherCode >= 80 && weatherCode <= 99);

  // QUÉ HACE: Traduce el código meteorológico WMO oficial a texto claro en español.
  String get conditionText {
    switch (weatherCode) {
      case 0:
        return 'Cielo despejado';
      case 1:
      case 2:
        return 'Parcialmente nublado';
      case 3:
        return 'Nublado';
      case 45:
      case 48:
        return 'Neblina';
      case 51:
      case 53:
        return 'Llovizna leve';
      case 55:
        return 'Llovizna densa';
      case 61:
        return 'Lluvia ligera';
      case 63:
        return 'Lluvia moderada';
      case 65:
        return 'Lluvia fuerte';
      case 80:
      case 81:
      case 82:
        return 'Chubasco de lluvia';
      case 95:
      case 96:
      case 99:
        return 'Tormenta eléctrica';
      default:
        return isRaining ? 'Lluvia activa' : 'Tiempo estable';
    }
  }

  // QUÉ HACE: Retorna el emoji representativo del clima actual.
  String get iconEmoji {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 2) return '⛅';
    if (weatherCode == 3) return '☁️';
    if (weatherCode >= 51 && weatherCode <= 55) return '🌦️';
    if (weatherCode >= 61 && weatherCode <= 65) return '🌧️';
    if (weatherCode >= 80 && weatherCode <= 82) return '🌧️';
    if (weatherCode >= 95) return '⛈️';
    return isRaining ? '🌧️' : '⛅';
  }
}

class WeatherService {
  WeatherService({Dio? client}) : _dio = client ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 6), receiveTimeout: const Duration(seconds: 6)));

  final Dio _dio;
  RealtimeWeatherData? _cachedWeather;
  DateTime? _lastWeatherFetch;
  String? _cachedRadarTileUrl;
  DateTime? _lastRadarFetch;

  // QUÉ HACE: Obtiene el clima en vivo de Open-Meteo para las coordenadas del empleado.
  // CÓMO: Realiza HTTP GET con caché inteligente de 3 minutos para evitar sobrecarga.
  Future<RealtimeWeatherData?> fetchCurrentWeather(double lat, double lng) async {
    final now = DateTime.now();
    if (_cachedWeather != null && _lastWeatherFetch != null && now.difference(_lastWeatherFetch!).inMinutes < 3) {
      return _cachedWeather;
    }

    try {
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,relative_humidity_2m,precipitation,rain,weather_code,wind_speed_10m';
      final response = await _dio.get<Map<String, dynamic>>(url);
      if (response.statusCode == 200 && response.data != null) {
        final current = response.data!['current'] as Map<String, dynamic>?;
        if (current != null) {
          _cachedWeather = RealtimeWeatherData(
            temperatureC: (current['temperature_2m'] as num?)?.toDouble() ?? 20.0,
            humidityPercent: (current['relative_humidity_2m'] as num?)?.toInt() ?? 60,
            precipitationMm: (current['precipitation'] as num?)?.toDouble() ?? 0.0,
            rainMm: (current['rain'] as num?)?.toDouble() ?? 0.0,
            weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
            windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
            updatedAt: now,
          );
          _lastWeatherFetch = now;
          return _cachedWeather;
        }
      }
    } catch (_) {}
    return _cachedWeather;
  }

  // QUÉ HACE: Obtiene el endpoint de las teselas del radar Doppler de lluvia más reciente.
  // CÓMO: Consulta RainViewer API y extrae el timestamp del radar más reciente.
  Future<String?> fetchLatestRadarTileUrl() async {
    final now = DateTime.now();
    if (_cachedRadarTileUrl != null && _lastRadarFetch != null && now.difference(_lastRadarFetch!).inMinutes < 8) {
      return _cachedRadarTileUrl;
    }

    try {
      final response = await _dio.get<String>('https://api.rainviewer.com/public/weather-maps.json');
      if (response.statusCode == 200 && response.data != null) {
        final data = jsonDecode(response.data!) as Map<String, dynamic>;
        final host = (data['host'] as String?) ?? 'https://tilecache.rainviewer.com';
        final radar = data['radar'] as Map<String, dynamic>?;
        final past = radar?['past'] as List<dynamic>?;
        if (past != null && past.isNotEmpty) {
          final latest = past.last as Map<String, dynamic>;
          final path = latest['path'] as String?;
          if (path != null && path.isNotEmpty) {
            // Formato de teselas transparentes de radar meteorológico de RainViewer HD:
            // host + path + /512/{z}/{x}/{y}/2/1_1.png (esquema de color 2: azul, verde, amarillo, rojo)
            _cachedRadarTileUrl = '$host$path/512/{z}/{x}/{y}/2/1_1.png';
            _lastRadarFetch = now;
            return _cachedRadarTileUrl;
          }
        }
      }
    } catch (_) {}
    return _cachedRadarTileUrl;
  }
}
