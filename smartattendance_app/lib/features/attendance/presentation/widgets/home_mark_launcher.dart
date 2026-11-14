// QUÉ HACE: Abre una captura para la identidad autenticada o el directorio.
// CÓMO: Busca exclusivamente su documento y muestra fallos sin crear personas.
// POR QUÉ: Un botón de asistencia no debe registrar datos de otro trabajador.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../photo_attendance/presentation/local_attendance_home.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/photo_capture_screen.dart';

Future<void> launchHomeMark(
    BuildContext context, WidgetRef ref, String? type) async {
  try {
    final session = ref.read(sessionControllerProvider);
    final user = session is SessionAuthenticated ? session.user : null;
    final actor = ref.read(localActorProvider);
    final workers = await ref.read(localWorkersProvider.future);
    final target = user == null
        ? null
        : workers
            .where((w) => w.document.trim() == user.cedula.trim())
            .firstOrNull;
    if (!context.mounted) return;
    if (target != null && (type != null || !actor.isAdmin)) {
      await Navigator.push<void>(
          context,
          MaterialPageRoute(
              builder: (_) => PhotoCaptureScreen(
                  worker: target, initialType: type ?? 'entrada')));
    } else if (actor.isAdmin) {
      await Navigator.push<void>(
          context,
          MaterialPageRoute(
              builder: (_) => LocalAttendanceHome(initialType: type)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Tu cuenta no tiene un registro de personal asignado. Consulta con tu supervisor.')));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el registro: $error')));
    }
  }
}
