import '../entities/user_entity.dart';

/// Interface for Authentication Repository.
/// Dependency Inversion Principle (DIP): ViewModels depend on this abstraction,
/// not on the concrete AuthRepositoryImpl.
abstract interface class AuthRepository {
  /// Login por cÃ©dula. [password] es obligatoria si la cuenta la tiene
  /// configurada (el servidor la exige).
  Future<(String token, UserEntity user)> loginByCedula(String cedula,
      {String? password});

  /// Login con Google: el id_token se verifica server-side contra el client
  /// ID configurado. La cuenta debe existir por correo en el sistema.
  Future<(String token, UserEntity user)> googleLogin(String idToken);

  /// Registro pÃºblico con contraseÃ±a. Retorna sesiÃ³n iniciada (tokens persistidos).
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

  Future<String> requestPasswordResetCode({required String cedula, required String correo});

  /// RecuperaciÃ³n de contraseÃ±a: identidad verificada con cÃ©dula + correo.
  /// Retorna el mensaje de confirmaciÃ³n del servidor.
  Future<String> resetPassword({
    required String cedula,
    required String correo,
    required String newPassword,
    required String code,
  });
}


