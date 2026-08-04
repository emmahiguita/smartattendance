// test/unit/validators/input_validators_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/core/validators/input_validators.dart';

void main() {
  group('InputValidators', () {
    group('validateCedula', () {
      test('debe retornar null para cédula válida', () {
        expect(InputValidators.validateCedula('1234567890'), isNull);
      });

      test('debe retornar null para cédula válida (máximo)', () {
        expect(InputValidators.validateCedula('1234567890123'), isNull);
      });

      test('debe rechazar cédula vacía', () {
        expect(
          InputValidators.validateCedula(''),
          isNotNull,
        );
      });

      test('debe rechazar cédula null', () {
        expect(
          InputValidators.validateCedula(null),
          isNotNull,
        );
      });

      test('debe rechazar cédula solo espacios', () {
        expect(
          InputValidators.validateCedula('   '),
          isNotNull,
        );
      });

      test('debe rechazar cédula muy corta (<6)', () {
        expect(
          InputValidators.validateCedula('12345'),
          isNotNull,
        );
      });

      test('debe rechazar cédula muy larga (>13)', () {
        expect(
          InputValidators.validateCedula('12345678901234'),
          isNotNull,
        );
      });

      test('debe rechazar cédula con caracteres no numéricos', () {
        expect(
          InputValidators.validateCedula('abcdefghij'),
          isNotNull,
        );
      });

      test('debe rechazar cédula con caracteres especiales', () {
        expect(
          InputValidators.validateCedula('123-456-789'),
          isNotNull,
        );
      });
    });

    group('validateEmail', () {
      test('debe retornar null para email válido', () {
        expect(InputValidators.validateEmail('test@example.com'), isNull);
      });

      test('debe retornar null para email null o vacío', () {
        expect(InputValidators.validateEmail(null), isNull);
        expect(InputValidators.validateEmail(''), isNull);
      });

      test('debe rechazar email sin @', () {
        expect(
          InputValidators.validateEmail('testexamplecom'),
          isNotNull,
        );
      });

      test('debe rechazar email sin dominio', () {
        expect(
          InputValidators.validateEmail('test@'),
          isNotNull,
        );
      });

      test('debe rechazar email sin extensión', () {
        expect(
          InputValidators.validateEmail('test@example'),
          isNotNull,
        );
      });
    });

    group('validatePassword', () {
      test('debe rechazar contraseña vacía', () {
        expect(
          InputValidators.validatePassword(''),
          isNotNull,
        );
      });

      test('debe rechazar contraseña null', () {
        expect(
          InputValidators.validatePassword(null),
          isNotNull,
        );
      });

      test('debe rechazar contraseña muy corta (<8)', () {
        expect(
          InputValidators.validatePassword('Pass12'),
          isNotNull,
        );
      });

      test('debe rechazar contraseña sin mayúsculas', () {
        expect(
          InputValidators.validatePassword('password123'),
          isNotNull,
        );
      });

      test('debe rechazar contraseña sin minúsculas', () {
        expect(
          InputValidators.validatePassword('PASSWORD123'),
          isNotNull,
        );
      });

      test('debe rechazar contraseña sin números', () {
        expect(
          InputValidators.validatePassword('PasswordPass'),
          isNotNull,
        );
      });

      test('debe aceptar contraseña válida', () {
        expect(
          InputValidators.validatePassword('Password123'),
          isNull,
        );
      });
    });

    group('validateRequired', () {
      test('debe retornar null para campo con texto', () {
        expect(InputValidators.validateRequired('test', 'Field'), isNull);
      });

      test('debe rechazar campo vacío', () {
        expect(
          InputValidators.validateRequired('', 'Field'),
          isNotNull,
        );
      });

      test('debe rechazar campo null', () {
        expect(
          InputValidators.validateRequired(null, 'Field'),
          isNotNull,
        );
      });

      test('debe rechazar campo solo espacios', () {
        expect(
          InputValidators.validateRequired('   ', 'Field'),
          isNotNull,
        );
      });
    });
  });
}

