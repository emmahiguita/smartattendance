// ============================================================================
// ARCHIVO: employee_avatar_service.dart
// QUÉ HACE: Gestiona la fotografía real en miniatura de cada empleado
//           (captura desde Cámara o selección desde Galería), su persistencia
//           local en el dispositivo y su sincronización inmediata con la sesión.
// CÓMO FUNCIONA:
// 1. Muestra un `CupertinoActionSheet` para elegir Cámara o Galería (`ImagePicker`).
// 2. Copia la imagen en `employee_avatars/avatar_<cedula>.jpg`.
// 3. Actualiza `usuarios_locales` en SQLite y `sessionControllerProvider` en RAM.
// POR QUÉ: Permite que cualquier empleado o administrador agregue su foto real
//          y aparezca su miniatura en Inicio, Barra Superior y Perfil (< 115 líneas).
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
  /// QUÉ HACE: Resuelve el archivo físico de la foto del empleado si existe.
  static File? resolveFile(String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.trim().isEmpty) return null;
    final clean = fotoUrl.replaceFirst('file://', '').trim();
    final f = File(clean);
    if (f.existsSync() && f.lengthSync() > 0) return f;
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
        message: Text('Selecciona o toma la fotografía de perfil para ${user.fullName}'),
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

      final ext = p.extension(picked.path).isNotEmpty ? p.extension(picked.path) : '.jpg';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final targetPath = p.join(folder.path, 'avatar_${user.cedula.trim()}_$ts$ext');
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
      await ref.read(sessionControllerProvider.notifier).authenticate(updatedUser);
    } catch (_) {}
  }
}
