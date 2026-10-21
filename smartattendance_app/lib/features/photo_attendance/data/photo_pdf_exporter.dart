import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/photo_record.dart';
import 'photo_day_table.dart';
import '../domain/journey_report.dart';
import '../domain/work_schedule.dart';
import 'package:image/image.dart' as img;

/// PDF por trabajador y día: cada etapa presenta su hora y foto. Generación en
/// isolate; lotes de 10 jornadas limitan RAM sin cortar una jornada entre archivos.
class PhotoPdfExporter {
  Future<List<String>> export(LocalAttendanceRepository repository) async {
    final root = await getTemporaryDirectory();
    final stem = 'asistencias_${DateTime.now().millisecondsSinceEpoch}';
    final files = <String>[];
    var skip = 0;
    while (true) {
      final days = await repository.days(skip: skip, limit: 10);
      if (days.isEmpty) break;
      final path = p.join(root.path, '${stem}_${files.length + 1}.pdf');
      await Isolate.run(() => _write(days, path));
      files.add(path);
      if (days.length < 10) break;
      skip += 10;
    }
    if (files.isEmpty) throw StateError('No hay asistencias para exportar.');
    return files;
  }

  static Future<void> _write(List<PhotoDay> days, String path) async {
    final document = pw.Document();
    for (final day in days) {
      final slots = <({String title, PhotoRecord? record})>[];
      for (final stage in PhotoDayTable.stages.entries) {
        final marks = day.marks(stage.key);
        if (marks.isEmpty) slots.add((title: stage.value, record: null));
        for (final mark in marks) {
          slots.add((title: stage.value, record: mark));
        }
      }
      for (var offset = 0; offset < slots.length; offset += 4) {
        final cards = <pw.Widget>[];
        for (final slot in slots.skip(offset).take(4)) {
          final mark = slot.record;
          pw.Widget image = pw.Center(
              child: pw.Text(
                  mark == null ? 'Sin registrar' : 'Foto no disponible'));
          if (mark != null) {
            try {
              image = pw.Image(pw.MemoryImage(await _thumbnail(mark.localPath)),
                  width: 220, height: 175, fit: pw.BoxFit.contain);
            } catch (_) {
              /* El reporte indica archivo faltante; no inventa evidencia. */
            }
          }
          final time =
              mark == null ? '--:--' : ColombiaClock.hour(mark.capturedAt);
          cards.add(pw.Container(
              width: 251,
              height: 210,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text('${slot.title}  $time',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Expanded(child: image),
                    pw.SizedBox(height: 4),
                    pw.Text(
                        mark?.location == null
                            ? 'Sin GPS guardado'
                            : '${mark!.location!.coordinates} | Precision ${mark.location!.accuracy.toStringAsFixed(0)} m',
                        style: const pw.TextStyle(fontSize: 8)),
                    if (mark?.location != null)
                      pw.Text(
                          'GPS: ${ColombiaClock.wall(mark!.location!.fixedAt).toIso8601String().replaceAll('Z', '')}',
                          style: const pw.TextStyle(fontSize: 8)),
                  ])));
        }
        document.addPage(pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28),
            header: (_) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Text('AsistenciaPro - Reporte de asistencia',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.Text(day.worker.name,
                          style: pw.TextStyle(
                              fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          'Cedula: ${day.worker.document} | Cargo: ${day.worker.job}'),
                      pw.Text(
                          'Inicio de jornada: ${day.date.toIso8601String().split('T').first} | Colombia UTC-5'),
                    ])),
            footer: (context) => pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8),
                child: pw.Text(
                    'Evidencia fotografica local, sin verificacion biometrica. Domingos/festivos pueden coincidir. Pagina ${context.pageNumber}.',
                    style: const pw.TextStyle(fontSize: 8))),
            build: (_) => [
                  pw.TableHelper.fromTextArray(
                      headers: ['Concepto', 'Resultado'],
                      data: JourneyReport.labels(day)
                          .entries
                          .map((e) => [e.key, e.value])
                          .toList(),
                      cellStyle: const pw.TextStyle(fontSize: 9),
                      headerStyle: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1),
                        1: const pw.FlexColumnWidth(2)
                      }),
                  pw.SizedBox(height: 12),
                  pw.Wrap(spacing: 12, runSpacing: 12, children: cards),
                ]));
      }
    }
    await File(path).writeAsBytes(await document.save(), flush: true);
  }

  /// Exporta una miniatura; la evidencia original permanece intacta en el m?vil.
  static Future<Uint8List> _thumbnail(String path) async {
    final source = img.decodeImage(await File(path).readAsBytes());
    if (source == null) throw const FormatException('Imagen no disponible.');
    final oriented = img.bakeOrientation(source);
    return img.encodeJpg(img.copyResize(oriented, width: 640), quality: 85);
  }
}
