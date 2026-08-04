// lib/features/profile/data/repositories/profile_repository_impl.dart
import 'package:dio/dio.dart';

import '../../../../core/exceptions/error_handler.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

final class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<UserEntity> updateProfile({
    String? nombre,
    String? apellido,
    String? correo,
    String? fechaNacimiento,
    String? telefono,
    String? direccion,
  }) async {
    try {
      final model = await _remote.updateProfile(
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        fechaNacimiento: fechaNacimiento,
        telefono: telefono,
        direccion: direccion,
      );
      return model.toEntity();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<UserEntity> uploadPhoto(String filePath) async {
    try {
      final model = await _remote.uploadPhoto(filePath);
      return model.toEntity();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
