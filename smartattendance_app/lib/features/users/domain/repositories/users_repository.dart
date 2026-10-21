// lib/features/users/domain/repositories/users_repository.dart
import '../../../auth/domain/entities/user_entity.dart';

abstract interface class UsersRepository {
  /// Lista empleados activos (GET /users — admin only, enforced server-side).
  Future<List<UserEntity>> listAll();

  /// Registra un nuevo empleado (POST /users — admin only).
  Future<UserEntity> createUser({
    required String nombre,
    required String apellido,
    required String cedula,
    required String correo,
    required String cargo,
    String? fechaNacimiento,
    String? telefono,
    String? direccion,
  });

  /// Sincroniza usuarios creados en modo offline con el backend.
  /// Retorna el número de usuarios sincronizados.
  Future<int> syncPendingUsers();
}
