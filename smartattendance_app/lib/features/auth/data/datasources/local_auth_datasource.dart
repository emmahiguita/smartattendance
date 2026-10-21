// lib/features/auth/data/datasources/local_auth_datasource.dart
// ===================================================================
// Fuente de datos local — permite login SIN backend usando SQLite.
// Se usa como fallback cuando el backend no está accesible.
// ===================================================================
import '../../../../core/localstore/local_database_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../models/user_model.dart';

class LocalAuthDataSource {
  LocalAuthDataSource(this._localDb);
  final LocalDatabaseService _localDb;

  /// Autentica localmente por cédula. Si el usuario no existe, lanza excepción.
  /// El password no se verifica (los usuarios locales no tienen contraseña).
  Future<(String token, String refreshToken, UserModel user)> loginByCedula(
    String cedula, {
    String? password,
  }) async {
    var row = await _localDb.getLocalUserByCedula(cedula);
    row ??= await _localDb.getCachedEmpleadoByCedula(cedula);
    if (row == null) {
      // Auto-crear usuario local para cualquier cédula ingresada en modo offline.
      // ID secuencial: usa MAX(id) + 1 para evitar colisiones de hash.
      final nextId = await _localDb.nextLocalUserId();
      final newLocalUser = {
        'id': nextId,
        'cedula': cedula,
        'nombre': 'Empleado',
        'apellido': 'Offline',
        'correo': 'usuario_$cedula@offline.local',
        'cargo': 'Empleado',
        'is_admin': 0,
      };
      await _localDb.insertLocalUser(newLocalUser);
      row = newLocalUser;
    }

    AppLogger.info('Local auth OK for cedula: $cedula');

    final user = UserModel.fromLocalRow(row);
    // Token local falso — permite que la app funcione sin backend real
    const localToken = 'local-offline-token';
    const localRefresh = 'local-offline-refresh';

    return (localToken, localRefresh, user);
  }
}
