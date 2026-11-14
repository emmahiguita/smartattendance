// ============================================================================
// ARCHIVO: worker_administration.dart
// QUÉ HACE: Autoriza cambios de personal y sincroniza la cuenta local.
// CÓMO FUNCIONA: Comprueba propiedad de cuadrilla y puestos permitidos (base +
//                personalizados del Admin) dentro de la transacción SQLite.
// POR QUÉ: Ocultar acciones en pantalla no impide modificar otro equipo por ID.
// ============================================================================
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/localstore/local_database_service.dart';
import '../../../../core/validators/input_validators.dart';
import '../../auth/data/datasources/local_auth_datasource.dart';
import '../../auth/data/datasources/local_password.dart';
import '../domain/local_actor.dart';
import '../domain/work_schedule.dart';
import 'photo_database.dart';
import 'worker_account_writer.dart';

class WorkerAdministration {
  WorkerAdministration(this.database, this.actor);
  final PhotoDatabase database;
  final LocalActor actor;

  Future<List<String>> _customPositions(DatabaseExecutor db) async {
    final rows = await db.query('local_settings', where: 'name=?', whereArgs: ['custom_job_positions']);
    if (rows.isEmpty) return const [];
    try {
      return (jsonDecode(rows.first['value'] as String? ?? '[]') as List).map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> requireCrew(DatabaseExecutor db, int id) async {
    final crews = await db.query('crews', where: 'id=?', whereArgs: [id]);
    if (crews.isEmpty || (!actor.isStrictAdmin &&
        (!actor.isSupervisor || crews.first['supervisor_document'] != actor.document.trim()))) {
      throw const FormatException('Solo puedes gestionar un equipo autorizado.');
    }
  }

  Future<Map<String, Object?>> worker(DatabaseExecutor db, int id, {bool changing = false}) async {
    final rows = await db.query('workers', where: 'id=?', whereArgs: [id]);
    if (rows.isEmpty) throw const FormatException('Trabajador no encontrado.');
    final row = rows.first;
    if (!actor.isStrictAdmin) {
      final crewId = row['crew_id'] as int?;
      if (crewId == null) throw const FormatException('El trabajador no pertenece a tu equipo.');
      await requireCrew(db, crewId);
      final custom = await _customPositions(db);
      if (changing && !actor.canCreateWorker(row['job'] as String, ownsCrew: true, customAllowed: custom)) {
        throw const FormatException('El supervisor solo puede gestionar personal operativo de su equipo.');
      }
    }
    return row;
  }

  Future<Database> _linked() async {
    final db = await database.database;
    await WorkerAccountWriter.attachAccounts(db, (await LocalDatabaseService().database).path);
    return db;
  }

  Future<void> assign(int workerId, int? crewId, WorkSchedule? schedule, String reference, {String? role}) async {
    final db = await _linked();
    await db.transaction((txn) async {
      final current = await worker(txn, workerId, changing: true);
      if (crewId != null) await requireCrew(txn, crewId);
      final job = role?.trim().isNotEmpty == true ? role!.trim() : current['job'] as String;
      final custom = await _customPositions(txn);
      if (!actor.isStrictAdmin && !actor.canCreateWorker(job, ownsCrew: true, customAllowed: custom)) {
        throw const FormatException('No puedes asignar cargos de mando.');
      }
      await txn.update('workers', {'crew_id': crewId, 'schedule_json': schedule?.encode(),
        'job': job, 'authorization_reference': reference,
        'authorization_at': DateTime.now().toUtc().toIso8601String()}, where: 'id=?', whereArgs: [workerId]);
      await txn.rawUpdate('UPDATE registration_accounts.usuarios_locales SET cargo=?,is_admin=? WHERE cedula=?',
        [job, LocalAuthDataSource.isRoleAdmin(job, current['document'] as String) ? 1 : 0, current['document']]);
    });
  }

  Future<void> delete(int id) async {
    final db = await _linked();
    await db.transaction((txn) async {
      final current = await worker(txn, id, changing: true);
      final doc = current['document'] as String;
      if (doc == actor.document.trim()) throw const FormatException('No puedes eliminar tu propia cuenta.');
      if ((await txn.query('photo_marks', columns: ['uuid'], where: 'worker_id=?', whereArgs: [id], limit: 1)).isNotEmpty) {
        throw const FormatException('El trabajador tiene historial; no se puede eliminar su información.');
      }
      await txn.delete('workers', where: 'id=?', whereArgs: [id]);
      await txn.rawDelete('DELETE FROM registration_accounts.usuarios_locales WHERE cedula=?', [doc]);
      await txn.rawDelete('DELETE FROM registration_accounts.empleados_cache WHERE cedula=?', [doc]);
    });
  }

  /// Restablecimiento local por un mando autorizado; no simula envío de códigos.
  Future<void> setPassword(int id, String password) async {
    if (InputValidators.validatePassword(password) != null) {
      throw const FormatException('Usa 8 caracteres o más con mayúscula, minúscula y número.');
    }
    final db = await _linked();
    final hash = await LocalPassword.hash(password);
    await db.transaction((txn) async {
      final current = await worker(txn, id, changing: true);
      if (password == current['document']) throw const FormatException('La cédula no puede ser la contraseña.');
      final count = await txn.rawUpdate('UPDATE registration_accounts.usuarios_locales SET password_hash=? WHERE cedula=?',
        [hash, current['document']]);
      if (count != 1) throw const FormatException('No existe una cuenta local vinculada a este trabajador.');
    });
  }
}
