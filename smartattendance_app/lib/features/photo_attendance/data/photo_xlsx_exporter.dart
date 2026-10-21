import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/photo_record.dart';
import 'photo_day_table.dart';
import 'xlsx_photo_drawing.dart';

/// Libro XLSX real, con miniaturas incrustadas y columnas por cada etapa. Todo
/// ocurre localmente en un isolate; cada archivo contiene hasta 50 jornadas.
class PhotoXlsxExporter {
  Future<List<String>> export(LocalAttendanceRepository repository) async {
    final root = await getTemporaryDirectory();
    final stem = 'asistencias_${DateTime.now().millisecondsSinceEpoch}';
    final files = <String>[];
    var skip = 0;
    while (true) {
      final days = await repository.days(skip: skip, limit: 50);
      if (days.isEmpty) break;
      final path = p.join(root.path, '${stem}_${files.length + 1}.xlsx');
      await Isolate.run(() => _write(days, path));
      files.add(path);
      if (days.length < 50) break;
      skip += 50;
    }
    if (files.isEmpty) throw StateError('No hay asistencias para exportar.');
    return files;
  }

  static String _escape(String text) => const HtmlEscape(HtmlEscapeMode.element)
      .convert(text)
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

  /// Columnas después de Z: AA, AB...; evita caracteres inválidos al añadir métricas.
  static String _column(int index) {
    var value = index + 1, result = '';
    while (value > 0) {
      value--;
      result = String.fromCharCode(65 + value % 26) + result;
      value ~/= 26;
    }
    return result;
  }

  static Future<void> _write(List<PhotoDay> days, String path) async {
    final archive = Archive();
    void xml(String name, String text) {
      final data = utf8.encode(text);
      archive.addFile(ArchiveFile(name, data.length, data));
    }

    const rel =
        'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
    const sheetNs = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
    xml('[Content_Types].xml',
        '''<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
      <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
      <Default Extension="xml" ContentType="application/xml"/><Default Extension="jpg" ContentType="image/jpeg"/>
      <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
      <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
      <Override PartName="/xl/drawings/drawing1.xml" ContentType="application/vnd.openxmlformats-officedocument.drawing+xml"/></Types>''');
    xml('_rels/.rels',
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="$rel/officeDocument" Target="xl/workbook.xml"/></Relationships>');
    xml('xl/workbook.xml',
        '<workbook xmlns="$sheetNs" xmlns:r="$rel"><sheets><sheet name="Asistencias" sheetId="1" r:id="rId1"/></sheets></workbook>');
    xml('xl/_rels/workbook.xml.rels',
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="$rel/worksheet" Target="worksheets/sheet1.xml"/></Relationships>');
    xml('xl/worksheets/_rels/sheet1.xml.rels',
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="$rel/drawing" Target="../drawings/drawing1.xml"/></Relationships>');
    final rows = StringBuffer();
    void row(int number, List<String> values, int height) {
      rows.write('<row r="$number" ht="$height" customHeight="1">');
      for (var col = 0; col < values.length; col++) {
        // Inline strings preserva cédulas y evita ejecutar fórmulas del usuario.
        rows.write(
            '<c r="${_column(col)}$number" t="inlineStr"><is><t xml:space="preserve">${_escape(values[col])}</t></is></c>');
      }
      rows.write('</row>');
    }

    row(1, PhotoDayTable.headers, 30);
    final drawing = XlsxPhotoDrawing(archive);
    for (var index = 0; index < days.length; index++) {
      final day = days[index];
      var count = 1, column = 5;
      for (final stage in PhotoDayTable.stages.keys) {
        final marks = day.marks(stage);
        if (marks.length > count) count = marks.length;
        for (var photo = 0; photo < marks.length; photo++) {
          await drawing.add(marks[photo].localPath, index + 1, column, photo);
        }
        column += 2;
      }
      row(index + 2, PhotoDayTable.cells(day), count * 75);
    }
    xml('xl/worksheets/sheet1.xml',
        '''<worksheet xmlns="$sheetNs" xmlns:r="$rel">
      <sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" state="frozen"/></sheetView></sheetViews>
      <cols><col min="1" max="1" width="15" customWidth="1"/><col min="2" max="2" width="28" customWidth="1"/>
      <col min="3" max="12" width="22" customWidth="1"/>
      <col min="13" max="16" width="48" customWidth="1"/>
      <col min="17" max="${PhotoDayTable.headers.length}" width="26" customWidth="1"/></cols>
      <sheetData>$rows</sheetData><autoFilter ref="A1:${_column(PhotoDayTable.headers.length - 1)}${days.length + 1}"/><drawing r:id="rId1"/></worksheet>''');
    drawing.finish();
    await File(path).writeAsBytes(ZipEncoder().encode(archive), flush: true);
  }
}
