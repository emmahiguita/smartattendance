// lib/features/users/data/repositories/users_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/localstore/local_database_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_remote_datasource.dart';

final class UsersRepositoryImpl implements UsersRepository {
  const UsersRepositoryImpl(this._remote, this._localDb);

  final UsersRemoteDataSource _remote;
  final LocalDatabaseService _localDb;

  @override
  Future<List<UserEntity>> listAll() async {
    try {
      final models = await _remote.listAll();
      // Cache employees locally for offline access
      final rows = models
          .map((m) => {
                'id': m.id,
                'cedula': m.cedula,
                'nombre': m.nombre,
                'apellido': m.apellido,
                'correo': m.correo,
                'cargo': m.cargo,
                'foto_url': m.fotoUrl,
                'telefono': m.telefono,
                'is_admin': 0,
              })
          .toList();
      await _localDb.cacheEmpleados(rows);
      return models.map((m) => m.toEntity()).toList();
    } on DioException catch (_) {
      // Offline: use local cache
      AppLogger.info('Offline mode: loading employees from local cache');
      var cached = await _localDb.getCachedEmpleados();
      if (cached.isEmpty) {
        cached = await _localDb.getAllLocalUsers();
      }
      return cached
          .map((r) => UserEntity(
                id: r['id'] as int,
                nombre: r['nombre'] as String,
                apellido: r['apellido'] as String,
                cedula: r['cedula'] as String,
                correo: (r['correo'] as String?) ?? '',
                cargo: (r['cargo'] as String?) ?? 'Empleado',
                fotoUrl: r['foto_url'] as String?,
                telefono: r['telefono'] as String?,
              ))
          .toList();
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
      // Cache the new employee locally
      await _localDb.insertLocalEmpleado({
        'id': model.id,
        'cedula': model.cedula,
        'nombre': model.nombre,
        'apellido': model.apellido,
        'correo': model.correo,
        'cargo': model.cargo,
        'foto_url': model.fotoUrl,
        'telefono': model.telefono,
        'is_admin': 0,
      });
      return model.toEntity();
    } on DioException catch (_) {
      // Offline: create locally with temp ID
      AppLogger.info('Offline mode: creating employee locally');
      final tempId = -1 * DateTime.now().millisecondsSinceEpoch;
      await _localDb.insertLocalEmpleado({
        'id': tempId,
        'cedula': cedula,
        'nombre': nombre,
        'apellido': apellido,
        'correo': correo,
        'cargo': cargo,
        'foto_url': null,
        'telefono': telefono,
        'is_admin': 0,
      });
      return UserEntity(
        id: tempId,
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
        correo: correo,
        cargo: cargo,
        telefono: telefono,
      );
    }
  }
}
