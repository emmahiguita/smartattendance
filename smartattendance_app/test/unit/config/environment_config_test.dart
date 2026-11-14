// test/unit/config/environment_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/core/config/environment_config.dart';
import 'package:smartattendance/core/location/traccar_service.dart';
import 'package:smartattendance/features/auth/presentation/viewmodels/login_viewmodel.dart';

void main() {
  group('EnvironmentConfig', () {
    test('debe tener baseUrl configurado', () {
      expect(EnvironmentConfig.baseUrl, isNotEmpty);
    });

    test('debe tener connectTimeout configurado', () {
      expect(EnvironmentConfig.connectTimeout, isNotNull);
      expect(EnvironmentConfig.connectTimeout, greaterThan(Duration.zero));
    });

    test('debe tener enableLogging configurado', () {
      expect(EnvironmentConfig.enableLogging, isA<bool>());
    });

    test('debe tener enableAnalytics configurado', () {
      expect(EnvironmentConfig.enableAnalytics, isA<bool>());
    });

    test('debe tener enforcedHttps configurado', () {
      expect(EnvironmentConfig.enforcedHttps, isA<bool>());
    });

    test('release sin APP_ENV usa producción segura', () {
      expect(EnvironmentConfig.environment, Environment.production);
      expect(EnvironmentConfig.enforcedHttps, isTrue);
      expect(Uri.parse(EnvironmentConfig.baseUrl).scheme, 'https');
    });

    test('interpreta ambientes sin depender de mayúsculas', () {
      expect(
        EnvironmentConfig.environmentFromName('DEVELOPMENT'),
        Environment.development,
      );
      expect(
        EnvironmentConfig.environmentFromName('staging'),
        Environment.staging,
      );
      expect(
        EnvironmentConfig.environmentFromName('production'),
        Environment.production,
      );
    });

    test('rechaza un APP_ENV desconocido', () {
      expect(
        () => EnvironmentConfig.environmentFromName('demo'),
        throwsArgumentError,
      );
    });

    test('rechaza API HTTP en staging y producción', () {
      expect(
        () => EnvironmentConfig.validateBaseUrl(
          'http://api.example.com/api/v1',
          requireHttps: true,
        ),
        throwsFormatException,
      );
      expect(
        EnvironmentConfig.validateBaseUrl(
          'https://api.example.com/api/v1',
          requireHttps: true,
        ),
        'https://api.example.com/api/v1',
      );
    });
  });

  group('TraccarService', () {
    test('no inventa un servidor TLS incompatible por defecto', () {
      expect(TraccarService.defaultServerUrl, isEmpty);
    });

    test('usa HTTPS al normalizar un host sin esquema', () {
      expect(
        TraccarService.normalizeServerUrl('demo.traccar.org:5055'),
        'https://demo.traccar.org:5055',
      );
    });

    test('rechaza HTTP inseguro salvo hosts locales de desarrollo', () {
      expect(
        () => TraccarService.normalizeServerUrl('http://example.com:5055'),
        throwsFormatException,
      );
      expect(
        TraccarService.normalizeServerUrl('http://localhost:5055'),
        'http://localhost:5055',
      );
    });

    test('descarta URLs persistidas antiguas que ya no son seguras', () {
      expect(
        TraccarService.normalizeStoredServerUrl(
          'http://legacy.example.com:5055',
        ),
        isNull,
      );
      expect(
        TraccarService.normalizeStoredServerUrl(
          'https://traccar.example.com',
        ),
        'https://traccar.example.com',
      );
    });
  });

  group('Google OAuth', () {
    test('Android puede usar la configuración OAuth nativa', () {
      expect(
        googleOAuthConfigurationError(
          serverClientId: '',
          iosClientId: '',
          isIOS: false,
        ),
        isNull,
      );
    });

    test('iOS explica qué credencial OAuth falta', () {
      expect(
        googleOAuthConfigurationError(
          serverClientId: '',
          iosClientId: 'ios-id',
          isIOS: true,
        ),
        contains('GOOGLE_SERVER_CLIENT_ID'),
      );
      expect(
        googleOAuthConfigurationError(
          serverClientId: 'server-id',
          iosClientId: '',
          isIOS: true,
        ),
        contains('GOOGLE_IOS_CLIENT_ID'),
      );
    });

    test('acepta configuración completa para iOS', () {
      expect(
        googleOAuthConfigurationError(
          serverClientId: 'server-id',
          iosClientId: 'ios-id',
          isIOS: true,
        ),
        isNull,
      );
    });
  });
}
