// test/app_smoke_test.dart
// ===================================================================
// Smoke test — unit tests que verifican la integridad del dominio sin
// depender de UI (widget tests van en widget_test.dart) ni de backend.
//
// Cubre: SessionState, UserEntity, AppConfig, InputValidators.
// Ejecuta: flutter test test/app_smoke_test.dart
// ===================================================================
import 'package:flutter_test/flutter_test.dart';

import 'package:smartattendance/core/auth/session_controller.dart';
import 'package:smartattendance/features/auth/domain/entities/user_entity.dart';
import 'package:smartattendance/core/config/app_config.dart';
import 'package:smartattendance/core/validators/input_validators.dart';

// ── UserEntity de prueba ───────────────────────────────────────────

const testUser = UserEntity(
  id: 1,
  nombre: 'Juan',
  apellido: 'Pérez',
  cedula: '1234567890',
  correo: 'juan@test.com',
  cargo: 'Desarrollador',
);

const testAdmin = UserEntity(
  id: 2,
  nombre: 'Admin',
  apellido: 'Sistema',
  cedula: '999888777',
  correo: 'admin@test.com',
  cargo: 'Administrador',
);

// ── Tests ───────────────────────────────────────────────────────────

void main() {
  // ═══════════════════════════════════════════════════════════════════
  // SESSION STATE
  // ═══════════════════════════════════════════════════════════════════

  group('SessionState', () {
    test('Unknown equals Unknown', () {
      expect(const SessionUnknown().sameAs(const SessionUnknown()), isTrue);
    });

    test('Unauthenticated equals Unauthenticated', () {
      expect(
        const SessionUnauthenticated().sameAs(const SessionUnauthenticated()),
        isTrue,
      );
    });

    test('Authenticated same user equals Authenticated same user', () {
      expect(
        const SessionAuthenticated(testUser).sameAs(const SessionAuthenticated(testUser)),
        isTrue,
      );
    });

    test('Authenticated different users are not equal', () {
      expect(
        const SessionAuthenticated(testUser).sameAs(const SessionAuthenticated(testAdmin)),
        isFalse,
      );
    });

    test('Different sealed subtypes are not equal', () {
      expect(const SessionUnknown().sameAs(const SessionUnauthenticated()), isFalse);
      expect(const SessionUnknown().sameAs(const SessionAuthenticated(testUser)), isFalse);
      expect(const SessionUnauthenticated().sameAs(const SessionAuthenticated(testUser)), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // USER ENTITY
  // ═══════════════════════════════════════════════════════════════════

  group('UserEntity', () {
    test('Equatable: same values → equal', () {
      const u1 = UserEntity(
        id: 1, nombre: 'A', apellido: 'B', cedula: '123',
        correo: 'a@b.com', cargo: 'Dev',
      );
      const u2 = UserEntity(
        id: 1, nombre: 'A', apellido: 'B', cedula: '123',
        correo: 'a@b.com', cargo: 'Dev',
      );
      expect(u1, equals(u2));
    });

    test('Equatable: different id → not equal', () {
      const u1 = UserEntity(
        id: 1, nombre: 'A', apellido: 'B', cedula: '123',
        correo: 'a@b.com', cargo: 'Dev',
      );
      const u2 = UserEntity(
        id: 2, nombre: 'A', apellido: 'B', cedula: '123',
        correo: 'a@b.com', cargo: 'Dev',
      );
      expect(u1, isNot(equals(u2)));
    });

    test('fullName: "nombre apellido"', () {
      expect(testUser.fullName, 'Juan Pérez');
    });

    test('optional fields default to null', () {
      expect(testUser.fechaNacimiento, isNull);
      expect(testUser.telefono, isNull);
      expect(testUser.direccion, isNull);
      expect(testUser.fotoUrl, isNull);
    });

    test('all props included in equality', () {
      const u1 = UserEntity(
        id: 1, nombre: 'X', apellido: 'Y', cedula: '1',
        correo: 'x@y.com', cargo: 'Z', telefono: '555',
      );
      const u2 = UserEntity(
        id: 1, nombre: 'X', apellido: 'Y', cedula: '1',
        correo: 'x@y.com', cargo: 'Z', telefono: '555',
      );
      expect(u1, equals(u2));

      const u3 = UserEntity(
        id: 1, nombre: 'X', apellido: 'Y', cedula: '1',
        correo: 'x@y.com', cargo: 'Z', telefono: '999',
      );
      expect(u1, isNot(equals(u3)));
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // APP CONFIG
  // ═══════════════════════════════════════════════════════════════════

  group('AppConfig', () {
    test('appVersion is 1.0.0', () {
      expect(AppConfig.appVersion, '1.0.0');
    });

    test('companyName is CONTROL AI', () {
      expect(AppConfig.companyName, 'CONTROL AI');
    });

    test('storage key constants are correct', () {
      expect(AppConfig.keyAccessToken, 'access_token');
      expect(AppConfig.keyRefreshToken, 'refresh_token');
      expect(AppConfig.keyUserId, 'user_id');
      expect(AppConfig.keyUserCedula, 'user_cedula');
      expect(AppConfig.keyUserName, 'user_name');
      expect(AppConfig.keyUserRole, 'user_role');
      expect(AppConfig.keyUserJson, 'user_json');
      expect(AppConfig.keySavedCedula, 'saved_cedula');
      expect(AppConfig.keySavedPassword, 'saved_password');
      expect(AppConfig.keyNotificationsEnabled, 'key_notifications_enabled');
    });

    test('fullPhotoUrl: null → empty', () {
      expect(AppConfig.fullPhotoUrl(null), isEmpty);
    });

    test('fullPhotoUrl: empty → empty', () {
      expect(AppConfig.fullPhotoUrl(''), isEmpty);
    });

    test('fullPhotoUrl: builds absolute URL from relative path', () {
      final url = AppConfig.fullPhotoUrl('/static/fotos/user1.jpg');
      expect(url, isNotEmpty);
      expect(url, contains('/static/fotos/user1.jpg'));
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // INPUT VALIDATORS
  // ═══════════════════════════════════════════════════════════════════

  group('InputValidators.validateCedula', () {
    test('null → error', () {
      expect(InputValidators.validateCedula(null), isNotNull);
    });

    test('empty → error', () {
      expect(InputValidators.validateCedula(''), isNotNull);
    });

    test('whitespace → error', () {
      expect(InputValidators.validateCedula('   '), isNotNull);
    });

    test('too short (<6) → error', () {
      expect(InputValidators.validateCedula('12345'), isNotNull);
      expect(InputValidators.validateCedula('1'), isNotNull);
    });

    test('too long (>13) → error', () {
      expect(InputValidators.validateCedula('12345678901234'), isNotNull);
    });

    test('non-numeric → error', () {
      expect(InputValidators.validateCedula('abcdefghij'), isNotNull);
      expect(InputValidators.validateCedula('123-456-789'), isNotNull);
      expect(InputValidators.validateCedula('123 456'), isNotNull);
    });

    test('valid 10-digit → OK', () {
      expect(InputValidators.validateCedula('1234567890'), isNull);
    });

    test('valid 6-digit (min) → OK', () {
      expect(InputValidators.validateCedula('123456'), isNull);
    });

    test('valid 13-digit (max) → OK', () {
      expect(InputValidators.validateCedula('1234567890123'), isNull);
    });
  });

  group('InputValidators.validateEmail', () {
    test('null → OK (opcional)', () {
      expect(InputValidators.validateEmail(null), isNull);
    });

    test('empty → OK (opcional)', () {
      expect(InputValidators.validateEmail(''), isNull);
    });

    test('valid email → OK', () {
      expect(InputValidators.validateEmail('test@example.com'), isNull);
      expect(InputValidators.validateEmail('user+tag@domain.co'), isNull);
    });

    test('no @ → error', () {
      expect(InputValidators.validateEmail('testexamplecom'), isNotNull);
    });

    test('no domain → error', () {
      expect(InputValidators.validateEmail('test@'), isNotNull);
    });

    test('no TLD → error', () {
      expect(InputValidators.validateEmail('test@domain'), isNotNull);
    });
  });

  group('InputValidators.validatePassword', () {
    test('null → error', () {
      expect(InputValidators.validatePassword(null), isNotNull);
    });

    test('empty → error', () {
      expect(InputValidators.validatePassword(''), isNotNull);
    });

    test('too short (<8) → error', () {
      expect(InputValidators.validatePassword('Pass12'), isNotNull);
    });

    test('no uppercase → error', () {
      expect(InputValidators.validatePassword('password123'), isNotNull);
    });

    test('no lowercase → error', () {
      expect(InputValidators.validatePassword('PASSWORD123'), isNotNull);
    });

    test('no digits → error', () {
      expect(InputValidators.validatePassword('PasswordPass'), isNotNull);
    });

    test('valid: uppercase + lowercase + digits + ≥8 chars → OK', () {
      expect(InputValidators.validatePassword('Password123'), isNull);
      expect(InputValidators.validatePassword('Abcdefg1'), isNull);
      expect(InputValidators.validatePassword('Z9xY8wV7uT6'), isNull);
    });
  });

  group('InputValidators.validateRequired', () {
    test('null → error', () {
      expect(InputValidators.validateRequired(null, 'Nombre'), isNotNull);
    });

    test('empty → error', () {
      expect(InputValidators.validateRequired('', 'Nombre'), isNotNull);
    });

    test('whitespace only → error', () {
      expect(InputValidators.validateRequired('   ', 'Nombre'), isNotNull);
    });

    test('valid text → OK', () {
      expect(InputValidators.validateRequired('Juan', 'Nombre'), isNull);
    });
  });
}
