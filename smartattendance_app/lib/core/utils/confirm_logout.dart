// lib/core/utils/confirm_logout.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';

/// Confirma con el usuario y cierra la sesión.
/// Único punto de implementación del diálogo "¿Cerrar sesión?" — lo usan
/// Perfil, Configuración y el panel Admin. Retorna true si la sesión terminó.
Future<bool> confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirm = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Estás seguro de que deseas salir?'),
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.pop(ctx, false),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Salir'),
        ),
      ],
    ),
  );

  if (confirm != true) return false;

  // El router observa la sesión y redirige a login por sí solo.
  await ref.read(sessionControllerProvider.notifier).logout();
  return true;
}
