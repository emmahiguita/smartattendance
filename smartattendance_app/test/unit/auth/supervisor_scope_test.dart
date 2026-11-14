// Comprueba que el alcance de lectura del supervisor no sea global.
import 'package:flutter_test/flutter_test.dart';
import 'package:smartattendance/features/photo_attendance/domain/local_actor.dart';
import 'package:smartattendance/core/utils/roles.dart';
import 'package:smartattendance/features/auth/data/datasources/local_auth_datasource.dart';

void main() {
  test('un puesto descriptivo no concede administración por contener una palabra', () {
    for (final role in ['No administrador', 'Administrador de redes', 'Auxiliar administrador']) {
      expect(AppRoles.isStrictAdmin(role), isFalse);
      expect(LocalAuthDataSource.isStrictAdministrator(role, '987654321'), isFalse);
    }
    expect(AppRoles.isStrictAdmin('Administrador General'), isTrue);
  });
  test('un supervisor filtra por su identidad aunque tenga acceso de gestión', () {
    const actor = LocalActor('987654321', true, isSupervisor: true);
    expect(actor.visibleWorkers('w.id'), isNot('1'));
    expect(actor.visibilityArgs, ['987654321', '987654321', '987654321']);
  });

  test('el administrador estricto puede consultar todos los trabajadores', () {
    const actor = LocalActor('123456789', true, isStrictAdmin: true);
    expect(actor.visibleWorkers('w.id'), '1');
    expect(actor.visibilityArgs, isEmpty);
  });

  test('solo administrador o supervisor pueden registrar personal', () {
    const employee = LocalActor('111111', false);
    const supervisor = LocalActor('222222', true, isSupervisor: true);
    expect(employee.canCreateWorker('Operario', ownsCrew: true), isFalse);
    expect(supervisor.canCreateWorker('Operario', ownsCrew: false), isFalse);
    expect(supervisor.canCreateWorker('Operario', ownsCrew: true), isTrue);
    expect(supervisor.canCreateWorker('Administrador', ownsCrew: true), isFalse);
    expect(supervisor.canCreateWorker('Supervisor', ownsCrew: true), isFalse);
    expect(supervisor.canCreateWorker('Otro rol sin validar', ownsCrew: true), isFalse);
  });

  test('ninguna cédula concede privilegios sin un rol administrativo', () {
    expect(AppRoles.isStrictAdmin('Colaborador', cedula: '1007331963'), isFalse);
    expect(LocalAuthDataSource.isStrictAdministrator('Colaborador', '1007331963'), isFalse);
    expect(AppRoles.isStrictAdmin('Administrador', cedula: '987654321'), isTrue);
  });
}
