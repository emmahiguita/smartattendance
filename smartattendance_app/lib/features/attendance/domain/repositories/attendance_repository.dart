// lib/features/attendance/domain/repositories/attendance_repository.dart
import '../entities/attendance_entity.dart';
import '../../data/models/today_employee_status.dart';

abstract interface class AttendanceRepository {
  /// Registra asistencia. Cuando [tipo] es null, el SERVIDOR decide
  /// entrada/salida según el estado de la jornada (C2).
  Future<AttendanceEntity> register(int userId, {String? tipo});
  Future<List<AttendanceEntity>> getByUser(int userId);
  Future<List<AttendanceEntity>> getAll();
  Future<List<AttendanceEntity>> getAllWithUsers();
  Future<List<TodayEmployeeStatus>> getTodayStatus();

  /// Sincroniza marcas capturadas offline con el servidor backend.
  Future<int> syncPendingRecords();

  /// Obtiene la cantidad de marcas pendientes de sincronización local.
  Future<int> getPendingCount();
}
