// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/exceptions/error_handler.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Concrete implementation of AuthRepository.
/// LSP: substitutable for AuthRepository everywhere.
/// SRP: orchestrates data source + secure storage; no UI concerns.
final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required FlutterSecureStorage storage,
  })  : _remote = remoteDataSource,
        _storage = storage;

  final AuthRemoteDataSource _remote;
  final FlutterSecureStorage _storage;

  @override
  Future<(String token, UserEntity user)> loginByCedula(
    String cedula, {
    String? password,
  }) async {
    try {
      final (token, refreshToken, userModel) =
          await _remote.loginByCedula(cedula, password: password);
      return _persistSession(token, refreshToken, userModel);
    } catch (e) {
      throw ErrorHandler.handle(e);
    }
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



