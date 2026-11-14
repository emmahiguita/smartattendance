// ============================================================================
// ARCHIVO: worker_account_writer.dart
// QUÉ HACE: Da de alta personal y su cuenta local como una sola operación.
// CÓMO FUNCIONA: Adjunta la base de cuentas y escribe ambas con journal de
//                reversión validando puestos base y puestos creados por Admin.
// POR QUÉ: Si falla la cuenta, sitio o trabajador, SQLite revierte todo (< 95 líneas).
// ============================================================================

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/validators/input_validators.dart';
import '../../auth/data/datasources/local_auth_datasource.dart';
import '../../auth/data/datasources/local_password.dart';
import '../domain/local_actor.dart';
import '../domain/worker_site.dart';
import '../domain/work_schedule.dart';

class WorkerAccountWriter {
  WorkerAccountWriter(this.db, this.accountsPath, this.actor);
  final Database db;
  final String accountsPath;
  final LocalActor actor;
  Future<void>? _attached;

  Future<void> _attach() async {
    await attachAccounts(db, accountsPath);
  }

  static Future<void> attachAccounts(Database db, String accountsPath) async {
    final databases = await db.rawQuery('PRAGMA database_list');
    if (!databases.any((row) => row['name'] == 'registration_accounts')) {
      await db.execute('ATTACH DATABASE ? AS registration_accounts', [accountsPath]);
    }
    // Una transacción entre archivos requiere journal de reversión, no WAL.
    await db.rawQuery('PRAGMA main.journal_mode = DELETE');
    await db.rawQuery('PRAGMA registration_accounts.journal_mode = DELETE');
  }

  Future<void> create(String name, String document, String role, {
    required String password, int? crewId, WorkSchedule? schedule,
    String? authorizationReference, WorkerSite? site,
  }) async {
    final doc = document.trim(), cleanName = name.trim(), job = role.trim();
    if (cleanName.isEmpty || InputValidators.validateCedula(doc) != null) {
      throw const FormatException('Revisa el nombre y la cédula de 6 a 13 dígitos.');
    }
    if (InputValidators.validatePassword(password) != null || password == doc) {
      throw const FormatException('Usa una contraseña individual de 8 caracteres o más con mayúscula, minúscula y número.');
    }
    if (site != null && (!site.isValid || crewId == null)) {
      throw const FormatException('Selecciona un equipo y un sitio válido con dirección.');
    }
    await (_attached ??= _attach());
    final hash = await LocalPassword.hash(password);
    try {
      await db.transaction((txn) async {
        final crews = crewId == null ? <Map<String, Object?>>[] :
            await txn.query('crews', where: 'id=?', whereArgs: [crewId]);
        if (crewId != null && crews.isEmpty) throw const FormatException('El equipo seleccionado ya no existe.');
        final customRows = await txn.query('local_settings', where: 'name=?', whereArgs: ['custom_job_positions']);
        final customPositions = customRows.isEmpty
            ? const <String>[]
            : (jsonDecode(customRows.first['value'] as String? ?? '[]') as List)
                .map((e) => e.toString())
                .toList();
        final owned = crews.isNotEmpty && crews.first['supervisor_document'] == actor.document.trim();
        if (!actor.canCreateWorker(job, ownsCrew: owned, customAllowed: customPositions)) {
          throw const FormatException('Solo puedes registrar personal permitido en tu propio equipo.');
        }
        final parts = cleanName.split(RegExp(r'\s+'));
        await txn.rawInsert('''INSERT INTO registration_accounts.usuarios_locales
          (cedula,nombre,apellido,correo,cargo,is_admin,password_hash) VALUES (?,?,?,?,?,?,?)''',
          [doc, parts.first, parts.skip(1).join(' '), '', job,
            LocalAuthDataSource.isRoleAdmin(job, doc) ? 1 : 0, hash]);
        await txn.insert('workers', {'name': cleanName, 'document': doc, 'job': job,
          'crew_id': crewId, 'schedule_json': schedule?.encode(),
          'authorization_reference': authorizationReference ?? 'Alta administrativa',
          'authorization_policy': 'Política General SmartAttendance',
          'authorization_at': DateTime.now().toUtc().toIso8601String()});
        if (site != null) {
          final zoneId = await txn.insert('work_zones', site.toMap());
          await txn.update('crews', {'zone_id': zoneId}, where: 'id=?', whereArgs: [crewId]);
        }
      });
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) throw const FormatException('Ya existe una persona registrada con ese documento.');
      rethrow;
    }
  }
}
