enum Environment { development, staging, production }

final class EnvironmentConfig {
  static const _environmentName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static final _configs = {
    Environment.development: _DevConfig(),
    Environment.staging: _StagingConfig(),
    Environment.production: _ProdConfig(),
  };

  static Environment get environment => environmentFromName(_environmentName);
  static _BaseConfig get _current => _configs[environment]!;

  static String get baseUrl => _current.baseUrl;
  static bool get enableLogging => _current.enableLogging;
  static bool get enableAnalytics => _current.enableAnalytics;
  static Duration get connectTimeout => _current.connectTimeout;
  static Duration get receiveTimeout => _current.receiveTimeout;
  static bool get enforcedHttps => _current.enforcedHttps;

  // QUÉ HACE: Convierte APP_ENV en un ambiente conocido y falla explícitamente.
  // CÓMO: Normaliza espacios y mayúsculas antes de resolver el enum.
  // POR QUÉ: Evita que un release caiga silenciosamente en desarrollo.
  static Environment environmentFromName(String value) {
    return switch (value.trim().toLowerCase()) {
      'development' || 'dev' => Environment.development,
      'staging' || 'stage' => Environment.staging,
      'production' || 'prod' => Environment.production,
      _ => throw ArgumentError.value(value, 'APP_ENV', 'Ambiente desconocido'),
    };
  }

  // QUÉ HACE: Valida la URL efectiva antes de entregarla a la capa de red.
  // CÓMO: Exige host absoluto y HTTPS cuando el ambiente lo requiere.
  // POR QUÉ: Evita configuraciones que ATS bloquearía en iOS.
  static String validateBaseUrl(String value, {required bool requireHttps}) {
    final clean = value.trim();
    final uri = Uri.tryParse(clean);
    if (uri == null || !const {'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      throw const FormatException('API_BASE_URL debe ser una URL absoluta.');
    }
    if (requireHttps && uri.scheme != 'https') {
      throw const FormatException(
        'API_BASE_URL debe usar HTTPS en staging y producción.',
      );
    }
    return clean;
  }

  static void validateEnvironment() {
    final selected = environment;
    assert(_configs.containsKey(selected), 'Unknown environment: $selected');
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
  @override
  Duration get connectTimeout => const Duration(seconds: 5);

  @override
  Duration get receiveTimeout => const Duration(seconds: 10);

  @override
  String get baseUrl => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000/api/v1',
      );

  @override
  bool get enableLogging => true;

  @override
  bool get enableAnalytics => false;

  @override
  bool get enforcedHttps => false;
}

final class _StagingConfig extends _BaseConfig {
  @override
  String get baseUrl => EnvironmentConfig.validateBaseUrl(
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://api-staging.smartattendance.io/api/v1',
        ),
        requireHttps: true,
      );

  @override
  bool get enableLogging => true;

  @override
  bool get enableAnalytics => true;

  @override
  Duration get connectTimeout => const Duration(seconds: 15);
}

final class _ProdConfig extends _BaseConfig {
  /// URL de producción predeterminada; su disponibilidad se verifica al desplegar.
  /// Render URL: https://{service-name}.onrender.com/api/v1
  @override
  String get baseUrl => EnvironmentConfig.validateBaseUrl(
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://smartattendance-api.onrender.com/api/v1',
        ),
        requireHttps: true,
      );

  @override
  bool get enableLogging => false;

  @override
  bool get enableAnalytics => true;

  @override
  Duration get connectTimeout => const Duration(seconds: 15);
}
