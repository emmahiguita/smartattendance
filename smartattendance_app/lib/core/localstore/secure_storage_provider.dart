// lib/core/localstore/secure_storage_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provides a singleton FlutterSecureStorage instance.
/// Lives in its own file so both [dio_provider] and [session_controller]
/// can depend on it without an import cycle.
///
/// Android options:
///   - encryptedSharedPreferences: true  → usa EncryptedSharedPreferences
///     (Tink-backed, recomendado Android 6+; API 35 / Android 15 compatible).
///   - resetOnError: true → si una key está corrupta (bad base-64) la limpia
///     automáticamente en lugar de hacer crash. El usuario deberá re-loguearse
///     una vez, pero la app no vuelve a fallar.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );
});
