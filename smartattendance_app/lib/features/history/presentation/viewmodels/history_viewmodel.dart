// lib/features/history/presentation/viewmodels/history_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/localstore/secure_storage_provider.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../attendance/data/repositories/attendance_repository_impl.dart'
    show attendanceRepositoryProvider;

class HistoryViewModel extends AsyncNotifier<List<AttendanceEntity>> {
  @override
  Future<List<AttendanceEntity>> build() async {
    // H2: sin sesión autenticada no hay historial que cargar.
    // Usamos ref.watch para reaccionar a cambios de sesión automáticamente.
    if (ref.watch(sessionControllerProvider) is! SessionAuthenticated) {
      return const [];
    }
    return _fetchHistory();
  }

  Future<List<AttendanceEntity>> _fetchHistory() async {
    final storage = ref.read(secureStorageProvider);
    final userIdStr = await storage.read(key: AppConfig.keyUserId);
    if (userIdStr == null) {
      throw AuthException(message: 'Usuario no autenticado');
    }

    final userId = int.tryParse(userIdStr);
    if (userId == null) {
      throw AuthException(message: 'ID de usuario inválido');
    }

    // Reutiliza el repositorio ya provisto (mismo Dio, sin duplicar instancias)
    final repository = ref.read(attendanceRepositoryProvider);
    final records = await repository.getByUser(userId);

    // Ordenar por fecha y hora descendente (más reciente primero)
    records.sort((a, b) {
      final dateCmp = b.fecha.compareTo(a.fecha);
      if (dateCmp != 0) return dateCmp;
      return b.hora.compareTo(a.hora);
    });
    return records;
  }

  Future<void> loadHistory() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchHistory());
  }
}

final historyViewModelProvider =
    AsyncNotifierProvider<HistoryViewModel, List<AttendanceEntity>>(
  () => HistoryViewModel(),
);
