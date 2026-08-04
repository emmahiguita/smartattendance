// lib/features/attendance/presentation/viewmodels/employee_today_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/exceptions/error_handler.dart';
import '../../data/models/today_employee_status.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../data/repositories/attendance_repository_impl.dart';

/// Estado del resumen de asistencia HOY (todos los empleados).
final employeeTodayProvider =
    StateNotifierProvider<EmployeeTodayViewModel, EmployeeTodayState>(
  (ref) => EmployeeTodayViewModel(ref.watch(attendanceRepositoryProvider)),
);

class EmployeeTodayState {
  final bool isLoading;
  final String? error;
  final List<TodayEmployeeStatus> employees;

  int get total => employees.length;
  int get aTiempo => employees.where((e) => e.estado == 'a_tiempo').length;
  int get tarde => employees.where((e) => e.estado == 'tarde').length;
  int get sinMarcar => employees.where((e) => e.estado == 'sin_marcar').length;

  const EmployeeTodayState({
    this.isLoading = false,
    this.error,
    this.employees = const [],
  });
}

class EmployeeTodayViewModel extends StateNotifier<EmployeeTodayState> {
  final AttendanceRepository _repository;

  EmployeeTodayViewModel(this._repository) : super(const EmployeeTodayState()) {
    _load();
  }

  Future<void> _load() async {
    state = const EmployeeTodayState(isLoading: true);
    try {
      final employees = await _repository.getTodayStatus();
      state = EmployeeTodayState(employees: employees);
    } catch (e) {
      state = EmployeeTodayState(error: ErrorHandler.handle(e).message);
    }
  }

  Future<void> refresh() => _load();
}
