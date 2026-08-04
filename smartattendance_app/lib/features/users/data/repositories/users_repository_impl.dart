// lib/features/users/data/repositories/users_repository_impl.dart
import 'package:dio/dio.dart';

import '../../../../core/exceptions/error_handler.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_remote_datasource.dart';

final class UsersRepositoryImpl implements UsersRepository {
  const UsersRepositoryImpl(this._remote);

  final UsersRemoteDataSource _remote;

  @override
  Future<List<UserEntity>> listAll() async {
    try {
      final models = await _remote.listAll();
      return models.map((m) => m.toEntity()).toList();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  @override
  Future<UserEntity> createUser({
    required String nombre,
    required String apellido,
    required String cedula,
    required String correo,
    required String cargo,
    String? fechaNacimiento,
    String? telefono,
    String? direccion,
  }) async {
    try {
      final model = await _remote.createUser(
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
        correo: correo,
        cargo: cargo,
        fechaNacimiento: fechaNacimiento,
        telefono: telefono,
        direccion: direccion,
      );
      return model.toEntity();
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }
}
