// ============================================================================
// ARCHIVO: auth_repository_impl.dart
// QUÉ HACE: Implementa el repositorio de autenticación combinando API remota
//           y verificación local SQLite (`LocalAuthDataSource`), persistiendo
//           tokens y perfil en `FlutterSecureStorage`.
// CÓMO FUNCIONA: Si hay red consulta `AuthRemoteDataSource`; ante modo offline
//                o caída de red, delega a `LocalAuthDataSource` pasando cédula
//                y contraseña para validación real.
// POR QUÉ: Cumple Clean Architecture (DIP/SRP) y evita bloqueos de red (< 165 líneas).
// ============================================================================

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/localstore/local_database_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/local_auth_datasource.dart';
import '../models/user_model.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required FlutterSecureStorage storage,
    required LocalDatabaseService localDb,
  })  : _remote = remoteDataSource,
        _storage = storage,
        _local = LocalAuthDataSource(localDb);

  final AuthRemoteDataSource _remote;
  final FlutterSecureStorage _storage;
  final LocalAuthDataSource _local;

  /// QUÉ HACE: Autentica por cédula y contraseña en modo online u offline.
  @override
  Future<(String token, UserEntity user)> loginByCedula(
    String cedula, {
    String? password,
    bool isOffline = false,
  }) async {
    if (isOffline) {
      AppLogger.info('Offline mode: validating credentials against local SQLite');
      return _localLogin(cedula, password: password);
    }
    try {
      final (token, refreshToken, userModel) =
          await _remote.loginByCedula(cedula, password: password);
      return _persistSession(token, refreshToken, userModel);
    } catch (e) {
      if (_isNetworkError(e)) {
        AppLogger.warning('Backend unreachable, validating against local SQLite');
        return _localLogin(cedula, password: password);
      }
      throw ErrorHandler.handle(e);
    }
  }

  /// QUÉ HACE: Ejecuta la autenticación contra las tablas SQLite locales reales.
  Future<(String token, UserEntity user)> _localLogin(
    String cedula, {
    String? password,
  }) async {
    try {
      final (token, refreshToken, userModel) =
          await _local.loginByCedula(cedula, password: password);
      return _persistSession(token, refreshToken, userModel);
    } on FormatException catch (e) {
      throw AuthException(message: e.message);
    } catch (e) {
      AppLogger.error('Local auth failed', error: e);
      throw AuthException(
        message: 'Usuario no encontrado en la nómina local.',
      );
    }
  }

  /// QUÉ HACE: Identifica si una excepción corresponde a falta de conectividad.
  bool _isNetworkError(Object e) {
    if (e is NetworkException) return true;
    if (e is DioException) {
      return e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;
    }
    return e is TimeoutException ||
        (e is Exception && e.toString().contains('SocketException'));
  }

  @override
  Future<(String token, UserEntity user)> googleLogin(String idToken) async {
    try {
      final (token, refreshToken, userModel) =
          await _remote.googleLogin(idToken);
      return _persistSession(token, refreshToken, userModel);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<(String token, UserEntity user)> register({
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
      final (token, refreshToken, userModel) = await _remote.register(
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
        correo: correo,
        password: password,
        telefono: telefono,
        cargo: cargo,
        fechaNacimiento: fechaNacimiento,
      );
      return _persistSession(token, refreshToken, userModel);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<String> requestPasswordResetCode({
    required String cedula,
    required String correo,
  }) =>
      _remote.requestPasswordResetCode(cedula: cedula, correo: correo);

  @override
  Future<String> resetPassword({
    required String cedula,
    required String correo,
    required String newPassword,
    required String code,
  }) async {
    try {
      return await _remote.resetPassword(
        cedula: cedula,
        correo: correo,
        newPassword: newPassword,
        code: code,
      );
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// QUÉ HACE: Cifra y guarda los tokens y atributos del usuario en Keystore/Keychain.
  Future<(String, UserEntity)> _persistSession(
    String token,
    String refreshToken,
    UserModel userModel,
  ) async {
    final user = userModel.toEntity();
    await Future.wait([
      _storage.write(key: AppConfig.keyAccessToken, value: token),
      if (refreshToken.isNotEmpty)
        _storage.write(key: AppConfig.keyRefreshToken, value: refreshToken),
      _storage.write(key: AppConfig.keyUserId, value: user.id.toString()),
      _storage.write(key: AppConfig.keyUserCedula, value: user.cedula),
      _storage.write(key: AppConfig.keyUserName, value: user.fullName),
      _storage.write(key: AppConfig.keyUserRole, value: user.cargo),
    ]);
    return (token, user);
  }
}
