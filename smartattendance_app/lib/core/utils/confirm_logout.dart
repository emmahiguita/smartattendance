// lib/core/utils/confirm_logout.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import '../auth/token_store.dart';
import '../network/session_revocation.dart';

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

  if (confirm != true || !context.mounted) return false;

  final tokens = ref.read(tokenStoreProvider);
  final refresh = tokens.refreshToken;
  final remote = tokens.accessToken != null &&
      !TokenStore.isLocalToken(tokens.accessToken);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final baseUrl = tokens.serverUrl;
  // QUÉ HACE: El cierre local no espera a la red para invalidar la sesión.
  final revoking = remote && refresh != null && baseUrl != null
      ? revokeRemoteSession(baseUrl, refresh)
      : Future.value(!remote);
  await ref.read(sessionControllerProvider.notifier).logout();
  if (!await revoking && messenger != null && messenger.mounted) {
    messenger.showSnackBar(const SnackBar(
        content: Text(
      'Sesión cerrada en este dispositivo. El servidor no confirmó la revocación.',
    )));
  }
  return true;
}
