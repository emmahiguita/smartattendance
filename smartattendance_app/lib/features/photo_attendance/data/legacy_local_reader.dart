import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Lectura de compatibilidad: no ejecuta migraciones, seeds ni sincronización
/// del almacén antiguo. Así se conserva la jornada que ya existía en el diseño.
class LegacyLocalReader {
  Future<List<Map<String, Object?>>> history(int userId,String document) async {
    final path = p.join(await getDatabasesPath(), 'smartattendance_offline.db');
    if (!await databaseExists(path)) return [];
    final db = await openDatabase(path, readOnly: true, singleInstance: false);
    try {
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='attendance_history'");
      if (tables.isEmpty) return [];
      // Un perfil local usa un ID propio: no basta que coincida el número 1.
      // Verificar también la cédula evita atribuirle la jornada de otra persona.
      var matches=false;
      for(final name in ['usuarios_locales','empleados_cache']){
        final exists=await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name=?",[name]);
        if(exists.isEmpty)continue;
        final users=await db.query(name,columns:['id'],where:'id=? AND cedula=?',whereArgs:[userId,document],limit:1);
        if(users.isNotEmpty){matches=true;break;}
      }
      if(!matches)return [];
      return await db.query('attendance_history',
          where: 'usuario_id = ?',
          whereArgs: [userId],
          orderBy: 'fecha DESC, hora DESC');
    } finally {
      await db.close();
    }
  }
}
