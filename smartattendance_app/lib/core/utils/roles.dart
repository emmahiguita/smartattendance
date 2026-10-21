import '../../features/auth/domain/entities/user_entity.dart';

/// Fuente única de verdad para roles administrativos.
/// Espejo del check del servidor (`ADMIN_ROLES` en `app/api/v1/deps.py`) —
/// el check del cliente es SOLO UX; la seguridad se impone server-side.
abstract final class AppRoles {
  /// Devuelve true si el usuario tiene privilegios administrativos 
  /// (usando la columna booleana del token/BD).
  static bool isAdminUser(UserEntity? user) {
    if (user == null) return false;
    return user.isAdmin;
  }
}
