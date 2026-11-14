// ============================================================================
// ARCHIVO: auth_repository_impl.dart
// QUÉ HACE: Implementa el repositorio de autenticación combinando API remota
//           y verificación local SQLite (`LocalAuthDataSource`), persistiendo
//           tokens y perfil en `FlutterSecureStorage`.
// CÓMO FUNCIONA: Aplica Offline-First: si hay credenciales válidas en SQLite
//                autentica inmediatamente (~10ms); si no, consulta al backend
//                con timeout estricto de 3s para evitar bloqueos por Render.
// POR QUÉ: Cumple Clean Architecture (DIP/SRP) y elimina demoras en login (< 225 líneas).
// ============================================================================

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/auth/token_store.dart';
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
    required TokenStore tokens,
  })  : _remote = remoteDataSource,
        _storage = storage,
        _local = LocalAuthDataSource(localDb),
        _tokens = tokens;

  final AuthRemoteDataSource _remote;
  final FlutterSecureStorage _storage;
  final LocalAuthDataSource _local;
  final TokenStore _tokens;

  /// QUÉ HACE: Autentica por cédula y contraseña con estrategia ultra-rápida.
  /// CÓMO: Prioriza resolución local si la cuenta existe en SQLite; de lo contrario
  ///      consulta el backend remoto con un límite de 3s para no congelar la app.
  /// POR QUÉ: Los despliegues remotos gratuitos en Render sufren cold-start de hasta 45s.
  @override
  Future<(String token, UserEntity user)> loginByCedula(
    String cedula, {
    String? password,
    bool isOffline = false,
  }) async {
    final cleanCedula = cedula.trim();
    final cleanPassword = (password ?? '').trim();
    final generation = _tokens.generation;

    if (isOffline) {
      AppLogger.info('Offline mode: validando credenciales directamente en SQLite local');
      return _localLogin(cleanCedula, cleanPassword, generation);
    }

    // 1. Intento de validación local inmediata (0 esperas de red)
    try {
      return await _localLogin(cleanCedula, cleanPassword, generation);
    } catch (_) {
      // Si la cuenta aún no existe en SQLite local, se consulta el servidor remoto
    }

    // 2. Consulta remota con límite de 3s y fallback ante caída o timeout
    try {
      final (token, refreshToken, userModel) = await _remote
          .loginByCedula(cleanCedula,
              password: cleanPassword.isEmpty ? null : cleanPassword)
          .timeout(const Duration(seconds: 3));
      return _persistSession(token, refreshToken, userModel, generation, serverUrl: _remote.serverUrl);
    } catch (e) {
      if (_isTransportFailure(e) || e is TimeoutException) {
        return _localLogin(cleanCedula, cleanPassword, generation);
      }
      throw ErrorHandler.handle(e);
    }
  }

  /// QUÉ HACE: Ejecuta la autenticación contra las tablas SQLite locales reales.
  Future<(String token, UserEntity user)> _localLogin(
    String cedula, String password, int generation,
  ) async {
    try {
      final (token, refreshToken, userModel) =
          await _local.loginByCedula(cedula, password: password);
      return _persistSession(token, refreshToken, userModel, generation);
    } on FormatException catch (e) {
      throw AuthException(message: e.message);
    } catch (e) {
      AppLogger.error('Local auth failed', error: e);
      throw AuthException(
        message: 'Usuario no encontrado en la nómina local.',
      );
    }
  }

  /// QUÉ HACE: Identifica fallos de red, timeouts o rutas 404/503 del backend.
  /// POR QUÉ: Permite fallback automático sin bloquear la experiencia del usuario.
  bool _isTransportFailure(Object e) {
    if (e is TimeoutException) return true;
    final cause = e is AppException ? e.originalError : e;
    if (cause is TimeoutException) return true;
    if (cause is DioException) {
      if (cause.response == null &&
          const {
            DioExceptionType.connectionTimeout,
            DioExceptionType.sendTimeout,
            DioExceptionType.receiveTimeout,
            DioExceptionType.connectionError,
          }.contains(cause.type)) {
        return true;
      }
      final code = cause.response?.statusCode;
      if (code == 404 || code == 502 || code == 503 || code == 504) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<(String token, UserEntity user)> googleLogin(String idToken) async {
    final generation = _tokens.generation;
    try {
      final (token, refreshToken, userModel) =
          await _remote.googleLogin(idToken);
      return _persistSession(token, refreshToken, userModel, generation, serverUrl: _remote.serverUrl);
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
    final generation = _tokens.generation;
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
      return _persistSession(token, refreshToken, userModel, generation, serverUrl: _remote.serverUrl);
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
    int expectedGeneration, {
    String? serverUrl,
    }
  ) => _tokens.serialize(() async {
    if (_tokens.generation != expectedGeneration) {
      throw AuthException(message: 'El inicio de sesión ya no está activo.');
    }
    _tokens.clear();
    final generation = _tokens.generation;
    final user = userModel.toEntity();
    await Future.wait([
      _storage.delete(key: AppConfig.keyUserJson),
      _storage.write(key: AppConfig.keyAccessToken, value: token),
      _storage.write(key: AppConfig.keyRefreshToken, value: refreshToken.isEmpty ? null : refreshToken),
      _storage.write(key: AppConfig.keySessionServer, value: serverUrl),
      _storage.write(key: AppConfig.keyUserId, value: user.id.toString()),
      _storage.write(key: AppConfig.keyUserCedula, value: user.cedula),
      _storage.write(key: AppConfig.keyUserName, value: user.fullName),
      _storage.write(key: AppConfig.keyUserRole, value: user.cargo),
    ]);
    if (_tokens.generation != generation) {
      throw AuthException(message: 'El inicio de sesión ya no está activo.');
    }
    _tokens
      ..accessToken = token
      ..refreshToken = refreshToken.isEmpty ? null : refreshToken
      ..serverUrl = serverUrl;
    return (token, user);
  });
}
