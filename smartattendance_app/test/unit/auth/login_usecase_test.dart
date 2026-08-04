// test/unit/auth/login_usecase_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smartattendance/features/auth/domain/entities/user_entity.dart';
import 'package:smartattendance/features/auth/domain/repositories/auth_repository.dart';
import 'package:smartattendance/features/auth/domain/usecases/login_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase loginUseCase;
  late MockAuthRepository mockRepository;

  const testCedula = '1234567890';
  const testUser = UserEntity(
    id: 1,
    nombre: 'Test',
    apellido: 'User',
    cedula: testCedula,
    correo: 'test@example.com',
    cargo: 'Developer',
  );
  const testToken = 'test-token-xyz';

  setUp(() {
    mockRepository = MockAuthRepository();
    loginUseCase = LoginUseCase(mockRepository);
  });

  group('LoginUseCase', () {
    test('debe retornar token y usuario cuando las credenciales son válidas',
        () async {
      when(() => mockRepository.loginByCedula(testCedula))
          .thenAnswer((_) async => (testToken, testUser));

      final result = await loginUseCase(testCedula);

      expect(result.$1, testToken);
      expect(result.$2.cedula, testCedula);
      expect(result.$2.id, 1);
      verify(() => mockRepository.loginByCedula(testCedula)).called(1);
    });

    test('debe lanzar ArgumentError si la cédula está vacía', () {
      expect(
        () => loginUseCase(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('debe lanzar ArgumentError si la cédula es solo espacios', () {
      expect(
        () => loginUseCase('   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('debe lanzar ArgumentError si la cédula es muy corta (<6 dígitos)', () {
      expect(
        () => loginUseCase('12345'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('debe lanzar ArgumentError si la cédula contiene caracteres no numéricos',
        () {
      expect(
        () => loginUseCase('abcdefghij'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('debe trimear la cédula antes de enviarla al repository', () async {
      when(() => mockRepository.loginByCedula(testCedula))
          .thenAnswer((_) async => (testToken, testUser));

      await loginUseCase('  $testCedula  ');

      verify(() => mockRepository.loginByCedula(testCedula)).called(1);
    });
  });
}

