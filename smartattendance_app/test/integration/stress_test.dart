// test/integration/stress_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:smartattendance/features/auth/domain/entities/user_entity.dart';
import 'package:smartattendance/core/validators/input_validators.dart';
import 'package:dio/dio.dart';

void main() {
  const runLiveTests = bool.fromEnvironment('RUN_LIVE_TESTS');
  group('Prueba Automatizada de EstrÃ©s y Carga de AutenticaciÃ³n', () {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000/api/v1'));
    final dataSource = AuthRemoteDataSource(dio);

    test('Ejecutar 30 peticiones concurrentes de Login (Stress Load Test)', () async {
      final Stopwatch stopwatch = Stopwatch()..start();
      const int concurrentRequests = 30;

      final List<Future<dynamic>> futures = List.generate(concurrentRequests, (index) {
        final cedula = index % 3 == 0
            ? '1007331963'
            : (index % 3 == 1 ? '1234567890' : '0987654321');
        return dataSource.loginByCedula(cedula);
      });

      final results = await Future.wait(futures);
      stopwatch.stop();

      expect(results.length, equals(concurrentRequests));
      for (final result in results) {
        final (token, refreshToken, user) = result;
        expect(token, isNotEmpty);
        expect(user.cedula, isNotEmpty);
      }

      // ignore: avoid_print â€” salida informativa de la prueba de estrÃ©s
      print('âœ… PRUEBA DE ESTRÃ‰S COMPLETADA: $concurrentRequests peticiones en ${stopwatch.elapsedMilliseconds} ms (${(concurrentRequests / (stopwatch.elapsedMilliseconds / 1000)).toStringAsFixed(1)} req/sec).');
    },
        timeout: const Timeout(Duration(seconds: 60)),
        skip: runLiveTests
            ? false
            : 'Requiere backend y datos seed. Ejecutar con --dart-define=RUN_LIVE_TESTS=true');

    test('ValidaciÃ³n masiva de entradas y registro', () {
      final List<String> cedulasValidas = [
        '1007331963',
        '1234567890',
        '0987654321',
        '1122334455',
        '5544332211'
      ];

      for (final cedula in cedulasValidas) {
        expect(InputValidators.validateCedula(cedula), isNull);
      }

      final List<String> cedulasInvalidas = ['123', '', 'abc12345', '123456789012345'];
      for (final cedula in cedulasInvalidas) {
        expect(InputValidators.validateCedula(cedula), isNotNull);
      }
    });

    test('CreaciÃ³n de usuario y entidad de sesiÃ³n', () {
      const newUser = UserEntity(
        id: 999,
        nombre: 'Prueba',
        apellido: 'EstrÃ©s',
        cedula: '999888777',
        correo: 'prueba@empresa.com',
        cargo: 'QA Automation',
      );

      expect(newUser.fullName, equals('Prueba EstrÃ©s'));
      expect(newUser.cedula, equals('999888777'));
    });
  });
}


