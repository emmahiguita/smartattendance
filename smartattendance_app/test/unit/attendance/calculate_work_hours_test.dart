// test/unit/attendance/calculate_work_hours_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/features/attendance/domain/entities/attendance_entity.dart';

AttendanceEntity _marka({
  required int id,
  required DateTime fecha,
  required int h,
  required int m,
  required int s,
  required String tipo,
}) =>
    AttendanceEntity(
      id: id,
      usuarioId: 1,
      tipo: tipo,
      fecha: fecha,
      hora: DateTime(fecha.year, fecha.month, fecha.day, h, m, s),
    );

void main() {
  final dia = DateTime(2026, 8, 3);

  group('calculateWorkedHoursLabel — tiempo laborado REAL', () {
    test('jornada completa con almuerzo → 8h 00m', () {
      final records = [
        _marka(id: 1, fecha: dia, h: 8, m: 0, s: 0, tipo: 'entrada'),
        _marka(id: 2, fecha: dia, h: 12, m: 0, s: 0, tipo: 'salida_almuerzo'),
        _marka(id: 3, fecha: dia, h: 13, m: 0, s: 0, tipo: 'regreso_almuerzo'),
        _marka(id: 4, fecha: dia, h: 17, m: 0, s: 0, tipo: 'salida'),
      ];
      expect(calculateWorkedHoursLabel(records), '8h 00m');
    });

    test('jornada sin almuerzo (entrada + salida) → 9h 00m', () {
      final records = [
        _marka(id: 1, fecha: dia, h: 8, m: 0, s: 0, tipo: 'entrada'),
        _marka(id: 2, fecha: dia, h: 17, m: 0, s: 0, tipo: 'salida'),
      ];
      expect(calculateWorkedHoursLabel(records), '9h 00m');
    });

    test('DOS jornadas el mismo día → suma AMBOS tramos (regresión 0h 00m)', () {
      // El bug original: map[tipo]=hora sobreescribía y daba 0h con
      // múltiples marcas del mismo tipo en el día.
      final records = [
        // Jornada 1 (corta, de prueba): 21:39:01 → 21:39:42
        _marka(id: 1, fecha: dia, h: 21, m: 39, s: 1, tipo: 'entrada'),
        _marka(id: 2, fecha: dia, h: 21, m: 39, s: 25, tipo: 'salida_almuerzo'),
        _marka(id: 3, fecha: dia, h: 21, m: 39, s: 35, tipo: 'regreso_almuerzo'),
        _marka(id: 4, fecha: dia, h: 21, m: 39, s: 42, tipo: 'salida'),
        // Jornada 2: 22:06:26 → 22:19:28 (13m 02s)
        _marka(id: 5, fecha: dia, h: 22, m: 6, s: 26, tipo: 'entrada'),
        _marka(id: 6, fecha: dia, h: 22, m: 19, s: 28, tipo: 'salida_almuerzo'),
      ];
      // Jornada 1: 24s + 7s = 31s ≈ 0m; Jornada 2: 13m 02s → total 13m.
      expect(calculateWorkedHoursLabel(records), '0h 13m');
    });

    test('jornada en curso (regreso sin salida) suma desde regreso hasta ahora', () {
      final now = DateTime(2026, 8, 3, 15, 30);
      final records = [
        _marka(id: 1, fecha: dia, h: 8, m: 0, s: 0, tipo: 'entrada'),
        _marka(id: 2, fecha: dia, h: 12, m: 0, s: 0, tipo: 'salida_almuerzo'),
        _marka(id: 3, fecha: dia, h: 13, m: 0, s: 0, tipo: 'regreso_almuerzo'),
      ];
      // 4h (mañana) + 2h 30m (en curso desde regreso) = 6h 30m
      expect(calculateWorkedHoursLabel(records, now: now), '6h 30m');
    });

    test('sin registros → 0h 00m', () {
      expect(calculateWorkedHoursLabel([]), '0h 00m');
    });

    test('orden de entrada desordenado no afecta el resultado (ordena interno)', () {
      final records = [
        _marka(id: 3, fecha: dia, h: 17, m: 0, s: 0, tipo: 'salida'),
        _marka(id: 1, fecha: dia, h: 8, m: 0, s: 0, tipo: 'entrada'),
        _marka(id: 2, fecha: dia, h: 12, m: 0, s: 0, tipo: 'salida_almuerzo'),
        _marka(id: 4, fecha: dia, h: 13, m: 0, s: 0, tipo: 'regreso_almuerzo'),
      ];
      expect(calculateWorkedHoursLabel(records), '8h 00m');
    });
  });
}
