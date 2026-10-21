import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'photo_database.dart';
import 'photo_day_reader.dart';
import 'photo_day_table.dart';
import '../domain/local_actor.dart';

/// CSV local de jornadas organizadas. UTF-8 con BOM y comillas preservan
/// acentos, cédulas, comas y varias horas en una celda al importar en Sheets.
class PhotoExporter {
  PhotoExporter(this.database, this.actor);
  final PhotoDatabase database;
  final LocalActor actor;
  static String cell(Object? value) {
    var text = value?.toString() ?? '';
    if (RegExp(r'^\s*[=+@-]').hasMatch(text)) text = "'$text";
    return '"${text.replaceAll('"', '""')}"';
  }

  Future<String> export() async {
    final root = await getTemporaryDirectory();
    final file = File(p.join(
        root.path, 'asistencias_${DateTime.now().millisecondsSinceEpoch}.csv'));
    final sink = file.openWrite();
    try {
      sink.write('\ufeff');
      sink.write('${PhotoDayTable.headers.map(cell).join(',')}\r\n');
      var skip = 0;
      while (true) {
        final days =
            await PhotoDayReader(database, actor).read(skip: skip, limit: 100);
        for (final day in days) {
          sink.write('${PhotoDayTable.cells(day).map(cell).join(',')}\r\n');
        }
        if (days.length < 100) break;
        skip += 100;
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    return file.path;
  }
}
