import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/features/photo_attendance/domain/shift_template.dart';
import 'package:smartattendance/features/photo_attendance/domain/work_schedule.dart';

void main() {
  test('la tolerancia nocturna cruza medianoche sin recortar minutos', () {
    const shift = ShiftTemplate(name: 'Noche', startMinute: 20, endMinute: 480,
        dailyMinutes: 460, nightStartMinute: 1200, nightEndMinute: 300);
    final schedule = shift.toScheduleWithTolerance(30);
    expect(schedule.markStartMinute, 1430);
    expect(schedule.markEndMinute, 510);
    expect(schedule.nightStartMinute, 1200);
    expect(schedule.nightEndMinute, 300);
  });
  test('conserva la jornada y aplica ventana fija, flexible o libre', () {
    const shift = ShiftTemplate(name: 'Día', startMinute: 480, endMinute: 960,
        dailyMinutes: 480);
    final fixed = shift.toScheduleWithTolerance(0);
    final flexible = shift.toScheduleWithTolerance(60);
    final unrestricted = shift.toScheduleWithTolerance(null);
    expect([fixed.markStartMinute, fixed.markEndMinute], [480, 960]);
    expect([flexible.markStartMinute, flexible.markEndMinute], [420, 1020]);
    expect([unrestricted.markStartMinute, unrestricted.markEndMinute], [null, null]);
    expect([flexible.startMinute, flexible.endMinute], [480, 960]);
  });
  test('la ventana libre no se presenta como una restricción fija', () {
    const schedule = WorkSchedule(480, false, startMinute: 480, endMinute: 960);
    expect(schedule.markWindowFormatted, 'Sin restricción horaria');
    expect(schedule.isTimeWithinMarkWindow(DateTime(2026, 11, 9, 22)), isTrue);
  });

  test('la ventana fija permite sus límites y rechaza fuera de ellos', () {
    const schedule = WorkSchedule(480, false, markStartMinute: 480, markEndMinute: 960);
    expect(schedule.isTimeWithinMarkWindow(DateTime(2026, 11, 9, 8)), isTrue);
    expect(schedule.isTimeWithinMarkWindow(DateTime(2026, 11, 9, 16)), isTrue);
    expect(schedule.isTimeWithinMarkWindow(DateTime(2026, 11, 9, 7, 59)), isFalse);
    expect(schedule.isTimeWithinMarkWindow(DateTime(2026, 11, 9, 16, 1)), isFalse);
  });

  test('la ventana nocturna atraviesa medianoche', () {
    const schedule = WorkSchedule(480, false, markStartMinute: 1320, markEndMinute: 360);
    expect(schedule.isTimeWithinMarkWindow(DateTime(2026, 11, 9, 23)), isTrue);
    expect(schedule.isTimeWithinMarkWindow(DateTime(2026, 11, 10, 5)), isTrue);
    expect(schedule.isTimeWithinMarkWindow(DateTime(2026, 11, 10, 12)), isFalse);
  });
}
