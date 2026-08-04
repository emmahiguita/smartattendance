// lib/core/config/environment_config.dart
import 'package:flutter/foundation.dart'
    show kIsWeb, TargetPlatform, defaultTargetPlatform;

enum Environment { development, staging, production }

final class EnvironmentConfig {
  // CAMBIAR SEGÚN AMBIENTE
  static const Environment _environment = Environment.production;

  static final _configs = {
    Environment.development: _DevConfig(),
    Environment.staging: _StagingConfig(),
    Environment.production: _ProdConfig(),
  };

  static _BaseConfig get _current => _configs[_environment]!;

  static String get baseUrl => _current.baseUrl;
  static bool get enableLogging => _current.enableLogging;
  static bool get enableAnalytics => _current.enableAnalytics;
  static Duration get connectTimeout => _current.connectTimeout;
  static Duration get receiveTimeout => _current.receiveTimeout;
  static bool get enforcedHttps => _current.enforcedHttps;

  static void validateEnvironment() {
    assert(
      _configs.containsKey(_environment),
      'Unknown environment: $_environment',
    );
  }
}

abstract base class _BaseConfig {
  String get baseUrl;
  bool get enableLogging;
  bool get enableAnalytics;
  Duration get connectTimeout => const Duration(seconds: 30);
  Duration get receiveTimeout => const Duration(seconds: 30);
  bool get enforcedHttps => true;
}

final class _DevConfig extends _BaseConfig {
  // baseUrl según plataforma de ejecución:
  //  - Web / Windows / macOS / Linux  → localhost (el backend corre en la misma máquina)
  //  - Android (físico / emulador)    → 127.0.0.1 (vía adb reverse) o 10.0.2.2 (emulador)
  @override
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8000/api/v1',
      );
    }
    return 'http://localhost:8000/api/v1';
  }

  @override
  bool get enableLogging => true;

  @override
  bool get enableAnalytics => false;

  @override
  bool get enforcedHttps => false;
}

final class _StagingConfig extends _BaseConfig {
  @override
  String get baseUrl => 'https://api-staging.smartattendance.io/api/v1';

  @override
  bool get enableLogging => true;

  @override
  bool get enableAnalytics => true;

  @override
  Duration get connectTimeout => const Duration(seconds: 15);
}

final class _ProdConfig extends _BaseConfig {
  /// Backend desplegado en Render.com — siempre disponible, no depende del PC.
  /// Render URL: https://{service-name}.onrender.com/api/v1
  @override
  String get baseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://smartattendance-api.onrender.com/api/v1',
      );

  @override
  bool get enableLogging => false;

  @override
  bool get enableAnalytics => true;

  @override
  Duration get connectTimeout => const Duration(seconds: 15);
}
