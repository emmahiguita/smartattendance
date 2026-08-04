// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:dio/dio.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/exceptions/error_handler.dart';
import '../models/user_model.dart';

/// Remote data source for auth operations.
/// SRP: HTTP calls for authentication. Sin fallbacks locales: si el servidor
/// no responde, el error real llega al usuario.
final class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<(String token, String refreshToken, UserModel user)> loginByCedula(
    String cedula, {
    String? password,
  }) async {
    try {
      AppLogger.logApiCall('POST', '/auth/login',
          data: {'cedula': cedula.trim()});

      final response = await _dio.post(
        '/auth/login',
        data: {
          'cedula': cedula.trim(),
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );
      return _parseAuthResponse(response);
    } on DioException catch (e) {
      AppLogger.error('Login failed', error: e);
      throw ErrorHandler.handle(e);
    }
  }

  /// Inicio de sesiÃ³n con Google: el id_token verificado por el SERVIDOR
  /// (aud = client ID configurado). Retorna los mismos tokens que /auth/login.
  Future<(String token, String refreshToken, UserModel user)> googleLogin(
    String idToken,
  ) async {
    try {
      AppLogger.logApiCall('POST', '/auth/google');

      final response = await _dio.post(
        '/auth/google',
        data: {'id_token': idToken},
      );
      return _parseAuthResponse(response);
    } on DioException catch (e) {
      AppLogger.error('Google login failed', error: e);
      throw ErrorHandler.handle(e);
    }
  }

  /// Registro pÃºblico real: crea la cuenta en el servidor y retorna tokens
  /// (login automÃ¡tico).
  Future<(String token, String refreshToken, UserModel user)> register({
    required String nombre,
    required String apellido,
    required String cedula,
    required String correo,
    required String password,
    String? telefono,
    String? cargo,
    String? fechaNacimiento,
  }) async {
    try {
      AppLogger.logApiCall('POST', '/auth/register',
          data: {'cedula': cedula.trim()});

      final response = await _dio.post(
        '/auth/register',
        data: {
          'nombre': nombre.trim(),
          'apellido': apellido.trim(),
          'cedula': cedula.trim(),
          'correo': correo.trim(),
          'password': password,
          if (telefono != null && telefono.trim().isNotEmpty)
            'telefono': telefono.trim(),
          if (cargo != null && cargo.trim().isNotEmpty) 'cargo': cargo.trim(),
          if (fechaNacimiento != null && fechaNacimiento.isNotEmpty)
            'fecha_nacimiento': fechaNacimiento,
        },
      );
      return _parseAuthResponse(response);
    } on DioException catch (e) {
      AppLogger.error('Register failed', error: e);
      throw ErrorHandler.handle(e);
    }
  }

  /// RecuperaciÃ³n real: identidad verificada server-side con cÃ©dula + correo.
  /// Retorna el mensaje de confirmaciÃ³n del servidor.
  Future<String> requestPasswordResetCode({required String cedula, required String correo}) async {
    try {
      final response = await _dio.post('/auth/reset-password/request', data: {'cedula': cedula.trim(), 'correo': correo.trim()});
      return (response.data as Map<String, dynamic>)['mensaje'] as String? ?? 'Código enviado.';
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
  Future<String> resetPassword({
    required String cedula,
    required String correo,
    required String newPassword,
    required String code,
  }) async {
    try {
      AppLogger.logApiCall('POST', '/auth/reset-password',
          data: {'cedula': cedula.trim()});

      final response = await _dio.post(
        '/auth/reset-password',
        data: {
          'cedula': cedula.trim(),
          'correo': correo.trim(),
          'new_password': newPassword,
          'code': code,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return data['mensaje'] as String? ??
          'ContraseÃ±a actualizada correctamente.';
    } on DioException catch (e) {
      AppLogger.error('Reset password failed', error: e);
      throw ErrorHandler.handle(e);
    }
  }

  (String, String, UserModel) _parseAuthResponse(Response response) {
    final data = response.data as Map<String, dynamic>;
    final token = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String? ?? '';
    final userModel = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    return (token, refreshToken, userModel);
  }
}


