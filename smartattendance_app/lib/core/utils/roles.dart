// lib/core/utils/roles.dart
/// Fuente única de verdad para roles administrativos.
/// Espejo del check del servidor (`ADMIN_ROLES` en `app/api/v1/deps.py`) —
/// el check del cliente es SOLO UX; la seguridad se impone server-side.
abstract final class AppRoles {
  static const Set<String> _adminRoles = {
    'administrador',
    'admin',
    'desarrollador'
  };

  /// True cuando [cargo] es un rol administrativo (normalizado a minúsculas).
  static bool isAdminRole(String? cargo) {
    if (cargo == null) return false;
    return _adminRoles.contains(cargo.trim().toLowerCase());
  }
}
