// lib/features/profile/data/datasources/profile_remote_datasource.dart
import 'package:dio/dio.dart';

import '../../../auth/data/models/user_model.dart';

final class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<UserModel> updateProfile({
    String? nombre,
    String? apellido,
    String? correo,
    String? fechaNacimiento,
    String? telefono,
    String? direccion,
  }) async {
    final response = await _dio.put(
      '/users/me',
      data: {
        if (nombre != null) 'nombre': nombre,
        if (apellido != null) 'apellido': apellido,
        if (correo != null) 'correo': correo,
        if (fechaNacimiento != null) 'fecha_nacimiento': fechaNacimiento,
        if (telefono != null) 'telefono': telefono,
        if (direccion != null) 'direccion': direccion,
      },
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Sube una foto de perfil (multipart JPEG/PNG). Reemplaza la anterior.
  Future<UserModel> uploadPhoto(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.put('/users/me/foto', data: formData);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
