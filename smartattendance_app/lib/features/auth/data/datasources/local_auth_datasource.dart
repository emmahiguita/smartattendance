// ============================================================================
// ARCHIVO: local_auth_datasource.dart
// QUÉ HACE: Autentica cuentas existentes contra su credencial local guardada.
// CÓMO FUNCIONA: Valida PBKDF2 o la credencial heredada exacta.
// POR QUÉ: El documento y las contraseñas predeterminadas no activan cuentas.
// ============================================================================

import 'package:uuid/uuid.dart';
import '../../../../core/localstore/local_database_service.dart';
import '../../../../core/utils/roles.dart';
import '../models/user_model.dart';
import 'local_password.dart';

final class LocalAuthDataSource {
  LocalAuthDataSource(this._dbService);
  final LocalDatabaseService _dbService;
  static const _uuid = Uuid();

  /// QUÉ HACE: Valida únicamente la credencial guardada y no admite la cédula como clave.
  static bool verifyLocalCredential(
      String document, String password, String stored) {
    if (password.isEmpty || stored.isEmpty || password == document) {
      return false;
    }
    return stored == password ||
        stored == _uuid.v5(Namespace.oid.value, 'pwd:$document:$password');
  }

  /// QUÉ HACE: Verifica si el usuario es estrictamente Administrador Principal / RRHH.
  static bool isStrictAdministrator(String? roleOrJob, String cedula) {
    return AppRoles.isStrictAdmin(roleOrJob, cedula: cedula);
  }

  /// QUÉ HACE: Verifica si el usuario tiene rol de Supervisor o Encargado de cuadrilla.
  static bool isSupervisorRole(String? roleOrJob) {
    final r = (roleOrJob ?? '').trim().toLowerCase();
    return r == 'supervisor' ||
        r.startsWith('supervisor ') ||
        r == 'encargado' ||
        r == 'encargada' ||
        r.startsWith('encargado ') ||
        r.startsWith('encargada ');
  }

  /// QUÉ HACE: Determina si el usuario tiene acceso a funciones de gestión/supervisión.
  static bool isRoleAdmin(String? roleOrJob, String cedula) {
    return isStrictAdministrator(roleOrJob, cedula) ||
        isSupervisorRole(roleOrJob);
  }

  /// QUÉ HACE: Autentica una cuenta ya existente contra SQLite local.
  /// CÓMO: Exige coincidencia con la credencial; rechaza la cédula como clave.
  /// POR QUÉ: Una migración no debe introducir una contraseña de acceso común.
  Future<(String token, String refreshToken, UserModel user)> loginByCedula(
    String cedula, {
    String? password,
  }) async {
    final cleanCedula = cedula.trim();
    final input = (password ?? '').trim();
    final row = await _dbService.getLocalUserByCedula(cleanCedula);
    final stored = (row?['password_hash'] as String? ?? '').trim();

    bool valid = false;
    if (row != null && input.isNotEmpty && input != cleanCedula) {
      valid = stored.startsWith('pbkdf2-sha256\$')
          ? await LocalPassword.verify(input, stored)
          : verifyLocalCredential(cleanCedula, input, stored);
    }

    if (row == null || !valid) {
      throw const FormatException(
        'Credenciales locales inválidas. Inicia sesión con tu contraseña o recupera tu cuenta.',
      );
    }

    final user = UserModel.fromLocalRow(row);
    final seed =
        '$cleanCedula:${DateTime.now().toUtc().millisecondsSinceEpoch}';
    final token = 'local_jwt_${_uuid.v5(Namespace.oid.value, seed)}';
    final refresh = 'local_ref_${_uuid.v5(Namespace.url.value, seed)}';
    return (token, refresh, user);
  }
}
