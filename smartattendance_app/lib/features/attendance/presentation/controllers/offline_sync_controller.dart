// lib/features/attendance/presentation/controllers/offline_sync_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/repositories/attendance_repository.dart';

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
  OfflineSyncController(this._ref, this._repo)
      : super(const OfflineSyncState(
            isOnline: true, pendingCount: 0, isSyncing: false)) {
    _init();
  }

  final Ref _ref;
  final AttendanceRepository _repo;

  Future<void> _init() async {
    await refreshPendingCount();

    // Listening to network changes
    _ref.listen<bool>(connectivityProvider, (previous, isOnline) async {
      state = state.copyWith(isOnline: isOnline);
      if (isOnline) {
        AppLogger.info(
            'Dispositivo re-conectado a internet. Iniciando auto-sincronización...');
        await triggerSync();
      }
    });
  }

  Future<void> refreshPendingCount() async {
    final count = await _repo.getPendingCount();
    state = state.copyWith(pendingCount: count);
  }

  Future<void> triggerSync() async {
    if (state.isSyncing) return;

    final count = await _repo.getPendingCount();
    if (count == 0) {
      state = state.copyWith(pendingCount: 0);
      return;
    }

    state = state.copyWith(isSyncing: true, pendingCount: count);

    try {
      final synced = await _repo.syncPendingRecords();
      final remaining = await _repo.getPendingCount();
      state = state.copyWith(
        isSyncing: false,
        pendingCount: remaining,
        lastSyncedCount: synced,
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
  return OfflineSyncController(ref, repo);
});
