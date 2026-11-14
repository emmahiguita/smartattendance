import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/features/photo_attendance/domain/photo_record.dart';
import 'package:smartattendance/features/photo_attendance/domain/work_schedule.dart';
import 'package:smartattendance/features/photo_attendance/domain/work_totals.dart';

void main() {
  test('las extras asignadas no aumentan el tiempo realmente marcado', () {
    PhotoRecord mark(String type, int hour) => PhotoRecord(uuid: type, workerId: 1,
      name: 'QA', document: '901000001', job: 'Operario', type: type,
      capturedAt: DateTime.utc(2026, 11, 9, hour), localPath: '/real-test-fixture');
    final totals = WorkTotals([mark('entrada', 8), mark('salida_almuerzo', 12),
      mark('regreso_almuerzo', 13), mark('salida', 17)],
      const WorkSchedule(480, true, assignedOvertimeMinutes: 120));
    expect(totals.worked, const Duration(hours: 8));
    expect(totals.additional, Duration.zero);
  });
}
