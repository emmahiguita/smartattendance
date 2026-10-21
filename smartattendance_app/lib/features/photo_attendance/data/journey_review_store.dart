import 'package:sqflite/sqflite.dart';
import '../domain/photo_record.dart';
import 'photo_database.dart';

/// Revisi?n local de jornadas. Conserva marcas y fotos; registra el responsable
/// y cada decisi?n por separado para no perder la revisi?n anterior al cambiarla.
class JourneyReviewStore {
  JourneyReviewStore(this.database,this.adminDocument);
  final PhotoDatabase database;
  final String adminDocument;
  Future<void> applySchedule(PhotoDay day) async {
    final workers=await (await database.database).query('workers',where:'id=?',whereArgs:[day.worker.workerId]);
    if(workers.isEmpty)throw const FormatException('Trabajador no encontrado.');
    final worker=workers.first;
    if (worker['schedule_json'] == null) {
      throw const FormatException('Primero asigna la jornada en Trabajadores.');
    }
    await (await database.database).update(
        'journeys',
        {
          'schedule_json': worker['schedule_json'],
          'approved_seconds': null,
          'reviewed_by': adminDocument,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
          'review_note': 'Horario aplicado expresamente por administrador',
        },
        where: 'id=? AND schedule_json IS NULL',
        whereArgs: [day.id]);
  }

  Future<void> review(PhotoDay day,
      {required bool approve, bool abandon = false}) async {
    if (!abandon && (!day.totals.complete || day.totals.additional == null)) {
      throw const FormatException(
          'No se aprueba una jornada incompleta o sin horario pactado.');
    }
    final db=await database.database;
    await db.transaction((tx)async{
      final current=await tx.query('journeys',where:'id=?',whereArgs:[day.id]);
      final count=Sqflite.firstIntValue(await tx.rawQuery('SELECT COUNT(*) FROM photo_marks WHERE journey_id=?',[day.id]));
      if(current.isEmpty||current.first['status']=='void'||count!=day.records.length||
          current.first['status']!=day.status) {
        throw const FormatException('La jornada cambió. Actualiza el historial antes de revisar.');
      }
      await tx.update(
        'journeys',
        {
          if (abandon) 'status': 'void',
          'approved_seconds':
              abandon ? null : (approve ? day.totals.additional!.inSeconds : 0),
          'reviewed_by': adminDocument,
          'reviewed_at': DateTime.now().toUtc().toIso8601String(),
          'review_note': abandon
              ? 'Cerrada como incompleta; conserva evidencia'
              : (approve
                  ? 'Adicional aprobado por administrador'
                  : 'Adicional no aprobado'),
        },
        where: 'id=?',
        whereArgs: [day.id]);
      await tx.insert('review_events',{
        'journey_id':day.id,'action':abandon?'incomplete':(approve?'approve':'reject'),
        'admin_document':adminDocument,'reviewed_at':DateTime.now().toUtc().toIso8601String(),
      });
    });
  }

}
