// lib/features/users/data/datasources/users_remote_datasource.dart
import 'package:dio/dio.dart';

import '../../../auth/data/models/user_model.dart';

final class UsersRemoteDataSource {
  const UsersRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<UserModel>> listAll() async {
    final response = await _dio.get('/users/');
    return (response.data as List)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserModel> createUser({
    required String nombre,
    required String apellido,
    required String cedula,
    required String correo,
    required String cargo,
    String? fechaNacimiento,
    String? telefono,
    String? direccion,
  }) async {
    final response = await _dio.post(
      '/users/',
      data: {
        'nombre': nombre,
        'apellido': apellido,
        'cedula': cedula,
        'correo': correo,
        'cargo': cargo,
        if (fechaNacimiento != null) 'fecha_nacimiento': fechaNacimiento,
        if (telefono != null) 'telefono': telefono,
        if (direccion != null) 'direccion': direccion,
      },
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
