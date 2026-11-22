// ============================================================================
// ARCHIVO: employee_avatar_service.dart
// QUÉ HACE: Gestiona la fotografía real en miniatura de cada empleado
//           (captura desde Cámara o selección desde Galería), su persistencia
//           local multiplataforma (iOS y Android) y su recuperación en disco.
// CÓMO FUNCIONA:
// 1. `resolveFile` verifica primero `fotoUrl` directo y por `basename` dentro
//    del contenedor activo de iOS/Android (`ApplicationSupportDirectory`),
//    evitando pérdida de imagen cuando iOS rota el UUID del sandbox.
// 2. `pickAndSavePhoto` guarda la imagen en `employee_avatars`, actualiza
//    SQLite (`usuarios_locales`) y `sessionControllerProvider`.
// POR QUÉ: Garantiza paridad 100% entre iOS y Android para el avatar (< 165 líneas).
// ============================================================================

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../auth/session_controller.dart';
import '../localstore/local_database_service.dart';

abstract final class EmployeeAvatarService {
  static String? _cachedSupportPath;

  static const List<String> _androidAvatarDirs = [
    '/data/user/0/io.smartattendance.attendance/files/employee_avatars',
    '/data/data/io.smartattendance.attendance/files/employee_avatars',
  ];

  // QUÉ HACE: Pre-carga el directorio de soporte nativo (iOS Library/Application Support
  //           y Android files) para resolución síncrona inmediata.
  static Future<void> ensureInitialized() async {
    if (_cachedSupportPath != null) return;
    try {
      final dir = await getApplicationSupportDirectory();
      _cachedSupportPath = p.join(dir.path, 'employee_avatars');
    } catch (_) {}
  }

  // QUÉ HACE: Resuelve sincrónicamente el archivo físico de la foto miniatura
  //           tanto en iOS (rotación de UUID de contenedor) como en Android.
  static File? resolveFile(String? fotoUrl, [String? cedula]) {
    if (_cachedSupportPath == null) {
      ensureInitialized();
    }

    if (fotoUrl != null && fotoUrl.trim().isNotEmpty) {
      final clean = fotoUrl.replaceFirst('file://', '').trim();
      final direct = File(clean);
      if (direct.existsSync() && direct.lengthSync() > 0) return direct;
      if (_cachedSupportPath != null) {
        final relocated = File(p.join(_cachedSupportPath!, p.basename(clean)));
        if (relocated.existsSync() && relocated.lengthSync() > 0) {
          return relocated;
        }
      }
    }

    final candidateDirs = <String>[
      if (_cachedSupportPath != null) _cachedSupportPath!,
      ..._androidAvatarDirs,
    ];

    final cleanCedula = (cedula ?? '').trim();
    for (final dirPath in candidateDirs) {
      try {
        final dir = Directory(dirPath);
        if (!dir.existsSync()) continue;
        final files = dir
            .listSync()
            .whereType<File>()
            .where((f) => f.lengthSync() > 0)
            .toList();
        if (files.isEmpty) continue;
        files.sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        if (cleanCedula.isNotEmpty) {
          final match = files
              .where((f) => p.basename(f.path).contains('avatar_${cleanCedula}_'))
              .firstOrNull;
          if (match != null) return match;
        }
        return files.first;
      } catch (_) {}
    }
    return null;
  }

  /// QUÉ HACE: Abre selector iOS (Cámara / Galería) y guarda la foto real del empleado.
  static Future<void> pickAndSavePhoto(
    BuildContext context,
    WidgetRef ref,
    UserEntity? user,
  ) async {
    if (user == null) return;
    final source = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Foto Real del Empleado'),
        message: Text(
            'Selecciona o toma la fotografía de perfil para ${user.fullName}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ImageSource.camera),
            child: const Text('Tomar foto con la Cámara'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
            child: const Text('Elegir imagen de la Galería'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 88,
      );
      if (picked == null) return;

      final supportDir = await getApplicationSupportDirectory();
      final folder = Directory(p.join(supportDir.path, 'employee_avatars'));
      await folder.create(recursive: true);
      _cachedSupportPath = folder.path;

      final ext =
          p.extension(picked.path).isNotEmpty ? p.extension(picked.path) : '.jpg';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final targetPath =
          p.join(folder.path, 'avatar_${user.cedula.trim()}_$ts$ext');
      final savedFile = await File(picked.path).copy(targetPath);

      try {
        final authDb = await LocalDatabaseService().database;
        await authDb.update(
          'usuarios_locales',
          {'foto_url': savedFile.path},
          where: 'cedula = ?',
          whereArgs: [user.cedula.trim()],
        );
      } catch (_) {}

      final updatedUser = UserEntity(
        id: user.id,
        nombre: user.nombre,
        apellido: user.apellido,
        cedula: user.cedula,
        correo: user.correo,
        cargo: user.cargo,
        fechaNacimiento: user.fechaNacimiento,
        telefono: user.telefono,
        direccion: user.direccion,
        fotoUrl: savedFile.path,
        isAdmin: user.isAdmin,
      );
      await ref
          .read(sessionControllerProvider.notifier)
          .authenticate(updatedUser);
    } catch (_) {}
  }
}
