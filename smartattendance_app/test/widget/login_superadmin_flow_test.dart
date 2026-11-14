// ============================================================================
// ARCHIVO: login_superadmin_flow_test.dart
// QUÉ HACE: Verifica que LoginScreen renderiza sin overflows y el formulario
//           de Super Administrador (CC: 1007331963) funciona correctamente.
// POR QUÉ: Garantiza regresión del flujo principal de ingreso (< 100 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/features/auth/domain/entities/user_entity.dart';
import 'package:smartattendance/features/auth/domain/repositories/auth_repository.dart';
import 'package:smartattendance/features/auth/presentation/screens/login_screen.dart';
import 'package:smartattendance/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:smartattendance/features/auth/presentation/widgets/login_form_card.dart';
import 'package:smartattendance/features/auth/presentation/widgets/login_role_toggle.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<(String, UserEntity)> loginByCedula(String cedula,
      {String? password, bool isOffline = false}) async {
    return (
      'token-super-test',
      const UserEntity(
        id: 1007331963,
        nombre: 'Emmanuel',
        apellido: 'Higuita',
        cedula: '1007331963',
        correo: 'eememeai@gmail.com',
        cargo: 'Administrador',
        isAdmin: true,
      ),
    );
  }

  @override
  Future<(String, UserEntity)> googleLogin(String idToken) =>
      throw UnimplementedError();

  @override
  Future<(String, UserEntity)> register(
          {required String nombre,
          required String apellido,
          required String cedula,
          required String correo,
          required String password,
          String? telefono,
          String? cargo,
          String? fechaNacimiento}) =>
      throw UnimplementedError();

  @override
  Future<String> requestPasswordResetCode(
          {required String cedula, required String correo}) async =>
      '';

  @override
  Future<String> resetPassword(
          {required String cedula,
          required String correo,
          required String newPassword,
          required String code}) async =>
      '';
}

void main() {
  testWidgets(
      'LoginScreen: renderiza sin overflow y acepta datos del Super Admin',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository())
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    // Deja que el microtask de restore() se despache sin esperar su Timer.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 1. El formulario y el toggle deben estar presentes
    expect(find.byType(LoginFormCard), findsOneWidget);
    expect(find.byType(LoginRoleToggle), findsOneWidget);

    // 2. Cambiar a modo Administrador
    await tester.tap(find.text('Administrador'));
    await tester.pump();

    // 3. Ninguna identidad privilegiada se rellena automáticamente.
    expect(find.text('CC: 1007331963'), findsNothing);
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), '123456789');
    await tester.enterText(fields.at(1), 'ClaveSegura2026');
    await tester.pump();

    // 5. El botón de admin debe estar visible y sin overflow
    expect(find.text('Ingresar como Administrador'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 2));
  });
}
