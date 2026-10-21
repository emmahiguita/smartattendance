// lib/features/auth/data/repositories/auth_repository_impl.dart
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

  @override
  Future<(String token, UserEntity user)> loginByCedula(
    String cedula, {
    String? password,
    bool isOffline = false,
  }) async {
    // Si NO hay internet, login local instantáneo — sin esperar timeout.
    if (isOffline) {
      AppLogger.info('Offline mode: skipping remote, using local auth');
      return _localLogin(cedula);
    }

    try {
      final (token, refreshToken, userModel) =
          await _remote.loginByCedula(cedula, password: password);
      return _persistSession(token, refreshToken, userModel);
    } catch (e) {
      // Si el intento remoto falló por error de red, intentar local.
      if (_isNetworkError(e)) {
        AppLogger.warning('Backend unreachable, falling back to local auth');
        return _localLogin(cedula);
      }
      throw ErrorHandler.handle(e);
    }
  }

  /// Login 100% offline — usa la DB local SQLite.
  Future<(String token, UserEntity user)> _localLogin(String cedula) async {
    try {
      final (token, refreshToken, userModel) =
          await _local.loginByCedula(cedula);
      return _persistSession(token, refreshToken, userModel);
    } catch (e) {
      AppLogger.error('Local auth also failed', error: e);
      throw Exception('Sin conexión y usuario no encontrado localmente. '
          'Conéctate a internet para el primer inicio de sesión.');
    }
  }

  /// Detecta si el error es de conectividad (no del servidor rechazando).
  bool _isNetworkError(Object e) {
    // NetworkException is thrown by ErrorHandler when Dio catches connection errors
    if (e is NetworkException) return true;
    if (e is DioException) {
      return e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;
    }
    // SocketException, TimeoutException, etc.
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
  Future<String> requestPasswordResetCode({required String cedula, required String correo}) => _remote.requestPasswordResetCode(cedula: cedula, correo: correo);

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



