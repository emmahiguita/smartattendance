import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/photo_record.dart';

/// Android puede cerrar la actividad mientras la cámara está abierta. Este
/// borrador conserva el trabajador y el tipo; recuperar una foto nunca marca
/// asistencia automáticamente: el usuario debe revisar y pulsar Guardar.
class CaptureDraft {
  Future<File> get _file async => File(p.join(
      (await getApplicationSupportDirectory()).path,
      'attendance_capture_draft.json'));

  Future<void> write(
      LocalWorker worker, String type, String? path, String captureId) async {
    final file = await _file;
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
        jsonEncode({
          'id': worker.id,
          'name': worker.name,
          'document': worker.document,
          'job': worker.job,
          'type': type,
          'path': path,
          'capture_id': captureId,
        }),
        flush: true);
    await temporary.rename(file.path);
  }

  Future<({LocalWorker worker, String type, String path, String? captureId})?>
      recover() async {
    final file = await _file;
    if (!await file.exists()) return null;
    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    String? path = data['path'] as String?;
    if (Platform.isAndroid) {
      final lost = await ImagePicker().retrieveLostData();
      if (lost.files?.isNotEmpty == true) path = lost.files!.first.path;
    }
    if (path == null || !await File(path).exists()) return null;
    return (
      worker: LocalWorker(
          id: data['id'] as int,
          name: data['name'] as String,
          document: data['document'] as String,
          job: data['job'] as String),
      type: data['type'] as String,
      path: path,
      captureId: data['capture_id'] as String?
    );
  }

  Future<void> clear() async =>
      (await _file).delete().then<void>((_) {}, onError: (Object error) {
        if (error is! FileSystemException) throw error;
      });
}
