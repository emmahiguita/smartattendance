// test/unit/attendance/attendance_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/features/attendance/data/models/attendance_model.dart';

void main() {
  group('AttendanceModel.fromJson — zona horaria del país', () {
    test('hora Bogotá (UTC-5) se convierte correctamente a UTC', () {
      final model = AttendanceModel.fromJson(const {
        'id': 1,
        'usuario_id': 1,
        'tipo': 'entrada',
        'fecha': '2026-08-03',
        'hora': '10:06:00.123456',
      });
      // 10:06 en Bogotá = 15:06 UTC. La conversión es determinista sin
      // importar el huso donde corra el test/dispositivo.
      expect(model.hora.toUtc().hour, 15);
      expect(model.hora.toUtc().minute, 6);
    });

    test('fecha y campos extra (cargo) se parsean', () {
      final model = AttendanceModel.fromJson(const {
        'id': 2,
        'usuario_id': 3,
        'tipo': 'salida',
        'fecha': '2026-08-03',
        'hora': '18:30:00',
        'nombre': 'Juan',
        'apellido': 'Perez',
        'cedula': '1234567890',
        'cargo': 'Desarrollador Senior',
      });
      expect(model.tipo, 'salida');
      expect(model.fullName, 'Juan Perez');
      expect(model.cargoEmpleado, 'Desarrollador Senior');
      expect(model.hora.toUtc().hour, 23); // 18:30 Bogotá = 23:30 UTC
      expect(model.hora.toUtc().minute, 30);
    });
  });
}
