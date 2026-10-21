import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// El selector nativo permite elegir WhatsApp, correo o Archivos. Abrir el
/// selector no demuestra entrega: el destinatario y el envío los decide el usuario.
Future<void> shareAttendanceFiles(
    BuildContext context, List<String> paths) async {
  final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
              title: const Text('Compartir datos personales'),
              content: const Text(
                  'El informe contiene documentos, fotos y ubicaciones. Compártelo únicamente con destinatarios autorizados por la empresa.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Elegir destinatario'))
              ]));
  if (confirm != true || !context.mounted) return;
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null
      ? const Rect.fromLTWH(0, 0, 1, 1)
      : box.localToGlobal(Offset.zero) & box.size;
  await SharePlus.instance.share(ShareParams(
    files: paths.map((path) => XFile(path)).toList(),
    subject: 'Reporte de asistencia',
    sharePositionOrigin: origin,
  ));
}
