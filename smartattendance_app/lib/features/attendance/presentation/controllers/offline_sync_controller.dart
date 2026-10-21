// lib/features/attendance/presentation/controllers/offline_sync_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/localstore/secure_storage_provider.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../../messaging/data/messaging_repository.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart'
    show ProfileRepositoryImpl;
import '../../../profile/presentation/viewmodels/edit_profile_viewmodel.dart'
    show profileRepositoryProvider;
import '../../../users/domain/repositories/users_repository.dart';
import '../../../users/presentation/viewmodels/users_viewmodel.dart'
    show usersRepositoryProvider;

class OfflineSyncState {
  const OfflineSyncState({
    required this.isOnline,
    required this.pendingCount,
    required this.isSyncing,
    this.lastSyncedCount = 0,
  });

  final bool isOnline;
  final int pendingCount;
  final bool isSyncing;
  final int lastSyncedCount;

  OfflineSyncState copyWith({
    bool? isOnline,
    int? pendingCount,
    bool? isSyncing,
    int? lastSyncedCount,
  }) {
    return OfflineSyncState(
      isOnline: isOnline ?? this.isOnline,
      pendingCount: pendingCount ?? this.pendingCount,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedCount: lastSyncedCount ?? this.lastSyncedCount,
    );
  }
}

class OfflineSyncController extends StateNotifier<OfflineSyncState> {
  OfflineSyncController(this._ref, this._repo, this._msgRepo, this._profileRepo, this._usersRepo, this._storage)
      : super(const OfflineSyncState(
            isOnline: false, pendingCount: 0, isSyncing: false)) {
    _init();
  }

  final Ref _ref;
  final AttendanceRepository _repo;
  final MessagingRepository _msgRepo;
  final ProfileRepositoryImpl _profileRepo;
  final UsersRepository _usersRepo;
  final FlutterSecureStorage _storage;

  /// Retorna true si la sesión actual es real (token del backend),
  /// false si es la sesión offline falsa ("local-offline-token").
  Future<bool> _hasRealSession() async {
    final token = await _storage.read(key: AppConfig.keyAccessToken);
    return token != null && token != 'local-offline-token';
  }

  Future<void> _init() async {
    await refreshPendingCount();

    // Escuchar cambios de conectividad
    _ref.listen<bool>(connectivityProvider, (previous, isOnline) async {
      state = state.copyWith(isOnline: isOnline);
      if (isOnline) {
        AppLogger.info(
            'Dispositivo re-conectado a internet. Iniciando auto-sincronización...');
        await triggerSync();
      }
    });

    // Escuchar cambios de sesión: si el usuario pasa de offline → online real
    // (token cambia de "local-offline-token" a uno real), disparar sync.
    _ref.listen<SessionState>(sessionControllerProvider, (previous, next) async {
      if (next is SessionAuthenticated && previous is! SessionAuthenticated) {
        AppLogger.info('Sesión real detectada. Verificando sync pendiente...');
        if (await _repo.getPendingCount() > 0) {
          await triggerSync();
        }
      }
    });
  }

  Future<void> refreshPendingCount() async {
    final count = await _repo.getPendingCount();
    state = state.copyWith(pendingCount: count);
  }

  Future<void> triggerSync() async {
    if (state.isSyncing) return;

    // No sincronizar si la sesión es offline (token falso).
    // El token "local-offline-token" será rechazado por el backend con 401
    // y el interceptor de Dio forzará logout, expulsando al usuario.
    if (!await _hasRealSession()) {
      AppLogger.info('Sync skipped: sesión offline (sin token real del backend).');
      return;
    }

    final count = await _repo.getPendingCount();
    if (count == 0) {
      state = state.copyWith(pendingCount: 0);
      // Aún puede haber mensajes offline pendientes — seguimos.
    }

    state = state.copyWith(isSyncing: true, pendingCount: count);

    try {
      // 1. Sincronizar usuarios PRIMERO para resolver tempIds
      final syncedUsers = await _usersRepo.syncPendingUsers();
      // 2. Sincronizar asistencia (usará los IDs reales si hubo cascade update)
      final synced = await _repo.syncPendingRecords();
      final syncedMsg = await _msgRepo.syncPendingMessages();
      final syncedProfile = await _profileRepo.syncPendingProfiles();
      final remaining = await _repo.getPendingCount();
      state = state.copyWith(
        isSyncing: false,
        pendingCount: remaining,
        lastSyncedCount: syncedUsers + synced + syncedMsg + syncedProfile,
      );
    } catch (e) {
      AppLogger.warning('Error en controlador de auto-sincronización: $e');
      state = state.copyWith(isSyncing: false);
    }
  }
}

final offlineSyncControllerProvider =
    StateNotifierProvider<OfflineSyncController, OfflineSyncState>((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  final msgRepo = ref.watch(messagingRepositoryProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);
  final usersRepo = ref.watch(usersRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return OfflineSyncController(ref, repo, msgRepo, profileRepo, usersRepo, storage);
});
