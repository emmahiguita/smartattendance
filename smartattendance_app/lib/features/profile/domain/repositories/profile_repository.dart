// lib/features/profile/domain/repositories/profile_repository.dart
import '../../../auth/domain/entities/user_entity.dart';

abstract interface class ProfileRepository {
  /// Actualiza nombre/apellido/correo/fechaNacimiento/telefono/direccion del usuario autenticado (PUT /users/me).
  /// [userId] permite fallback offline: si no hay red, guarda en SQLite local.
  Future<UserEntity> updateProfile({
    String? nombre,
    String? apellido,
    String? correo,
    String? fechaNacimiento,
    String? telefono,
    String? direccion,
    int? userId,
  });

  /// Sube una foto de perfil (multipart JPEG/PNG). Reemplaza la anterior.
  Future<UserEntity> uploadPhoto(String filePath);
}
