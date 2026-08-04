import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/exceptions/error_handler.dart';
import '../../../../core/logging/app_logger.dart';

// attendanceRepositoryProvider se importa de attendance_repository_impl.dart

final adminDashboardProvider =
    StateNotifierProvider<AdminDashboardViewModel, AdminDashboardState>((ref) {
  // H2: al cambiar la sesión (login/logout) el dashboard se recrea y
  // descarta los datos del usuario anterior.
  ref.watch(sessionControllerProvider);
  final repository = ref.watch(attendanceRepositoryProvider);
  return AdminDashboardViewModel(repository);
});

class AdminDashboardState {
  final bool isLoading;
  final String? error;
  final List<AttendanceModel> attendances;
  final DateTime? lastSyncTime;

  /// Empleados ÚNICOS con al menos una marca del tipo dado hoy.
  /// (Contar registros inflaba con dobles marcas del mismo día.)
  int _empleadosUnicosHoy(String tipo) {
    final today = DateTime.now();
    return attendances
        .where((a) =>
            a.tipo == tipo &&
            a.fecha.day == today.day &&
            a.fecha.month == today.month &&
            a.fecha.year == today.year)
        .map((a) => a.usuarioId)
        .toSet()
        .length;
  }

  int get totalEntradasHoy => _empleadosUnicosHoy('entrada');

  int get totalSalidasHoy => _empleadosUnicosHoy('salida');

  int get totalEmpleados => attendances.map((a) => a.usuarioId).toSet().length;

  /// Ausentes HOY = empleados sin NINGUNA entrada hoy (empleados únicos).
  int get totalAusentesHoy {
    final ausentes = totalEmpleados - totalEntradasHoy;
    return ausentes < 0 ? 0 : ausentes;
  }

  List<int> get weeklyAttendanceChart {
    final today = DateTime.now();
    final counts = List.filled(7, 0);
    for (final a in attendances) {
      if (a.tipo == 'entrada') {
        final diff = DateTime(today.year, today.month, today.day)
            .difference(DateTime(a.fecha.year, a.fecha.month, a.fecha.day))
            .inDays;
        if (diff >= 0 && diff < 7) {
          counts[6 - diff]++;
        }
      }
    }
    return counts;
  }

  String get lastSyncLabel {
    if (lastSyncTime == null) return 'Nunca';
    final diff = DateTime.now().difference(lastSyncTime!);
    if (diff.inSeconds < 60) return 'Hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    return 'Hace ${diff.inHours}h';
  }

  AdminDashboardState({
    this.isLoading = false,
    this.error,
    this.attendances = const [],
    this.lastSyncTime,
  });

  AdminDashboardState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<AttendanceModel>? attendances,
    DateTime? lastSyncTime,
  }) {
    return AdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      // clearError=true limpia explícitamente; pasar error=valor lo establece;
      // de lo contrario conserva el error anterior.
      error: clearError ? null : (error ?? this.error),
      attendances: attendances ?? this.attendances,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class AdminDashboardViewModel extends StateNotifier<AdminDashboardState> {
  final AttendanceRepository _repository;

  AdminDashboardViewModel(this._repository) : super(AdminDashboardState()) {
    _loadData();
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Use the enriched endpoint that includes user names
      final attendances = await _repository.getAllWithUsers();

      // AttendanceModel extiende AttendanceEntity: cast directo, sin reconstruir
      final models = attendances.cast<AttendanceModel>();

      state = state.copyWith(
        isLoading: false,
        attendances: models,
        lastSyncTime: DateTime.now(),
        clearError: true,
      );
      AppLogger.info('Admin dashboard loaded: ${models.length} records');
    } catch (e) {
      AppLogger.error('Failed to load admin dashboard', error: e);
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.handle(e).message,
      );
    }
  }

  Future<void> refresh() async {
    await _loadData();
  }
}
