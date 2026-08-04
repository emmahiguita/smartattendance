// test/unit/config/environment_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/core/config/environment_config.dart';

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
  });
}

