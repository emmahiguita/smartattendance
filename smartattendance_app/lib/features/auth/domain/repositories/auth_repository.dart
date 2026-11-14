// ============================================================================
// ARCHIVO: auth_repository.dart
// QUÉ HACE: Contrato de interfaz del repositorio de autenticación (DIP).
// CÓMO FUNCIONA: Define los métodos requeridos para autenticación por cédula,
//                Google, registro y restablecimiento de contraseña.
// POR QUÉ: Desacopla la lógica de presentación del origen concreto de datos.
// ============================================================================

import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  /// Login por cédula. [password] es obligatoria si la cuenta la tiene
  /// configurada (el servidor la exige).
  /// [isOffline] salta el intento remoto y va directo a auth local (SQLite).
  Future<(String token, UserEntity user)> loginByCedula(
    String cedula, {
    String? password,
    bool isOffline = false,
  });

  /// Login con Google: el id_token se verifica server-side contra el client
  /// ID configurado. La cuenta debe existir por correo en el sistema.
  Future<(String token, UserEntity user)> googleLogin(String idToken);

  /// Registro público con contraseña. Retorna sesión iniciada (tokens persistidos).
  Future<(String token, UserEntity user)> register({
    required String nombre,
    required String apellido,
    required String cedula,
    required String correo,
    required String password,
    String? telefono,
    String? cargo,
    String? fechaNacimiento,
  });

  /// Solicita el código de restablecimiento enviado al correo institucional.
  Future<String> requestPasswordResetCode({
    required String cedula,
    required String correo,
  });

  /// Recuperación de contraseña: identidad verificada con cédula + correo + código OTP.
  /// Retorna el mensaje de confirmación del servidor.
  Future<String> resetPassword({
    required String cedula,
    required String correo,
    required String newPassword,
    required String code,
  });
}
