// lib/core/localstore/secure_storage_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provides a singleton FlutterSecureStorage instance.
/// Lives in its own file so both [dio_provider] and [session_controller]
/// can depend on it without an import cycle.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});
