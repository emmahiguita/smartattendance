// lib/shared/widgets/offline_status_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/attendance/presentation/controllers/offline_sync_controller.dart';

class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(offlineSyncControllerProvider);

    if (syncState.isOnline &&
        syncState.pendingCount == 0 &&
        !syncState.isSyncing) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    IconData iconData;
    String message;

    if (!syncState.isOnline) {
      bgColor = const Color(0xFFD97706); // Amber
      iconData = Icons.wifi_off_rounded;
      message = syncState.pendingCount > 0
          ? 'Modo Desconectado — ${syncState.pendingCount} marcas guardadas en cola local'
          : 'Modo Desconectado — Sin conexión a internet';
    } else if (syncState.isSyncing) {
      bgColor = const Color(0xFF2563EB); // Blue
      iconData = Icons.sync_rounded;
      message =
          'Sincronizando ${syncState.pendingCount} marcas offline con el servidor...';
    } else if (syncState.pendingCount > 0) {
      bgColor = const Color(0xFF059669); // Emerald
      iconData = Icons.cloud_upload_rounded;
      message =
          'Conectado — ${syncState.pendingCount} marcas pendientes por sincronizar';
    } else {
      return const SizedBox.shrink();
    }

    return Material(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: () {
            if (syncState.isOnline && syncState.pendingCount > 0) {
              ref.read(offlineSyncControllerProvider.notifier).triggerSync();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (syncState.isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(iconData, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (syncState.isOnline &&
                    syncState.pendingCount > 0 &&
                    !syncState.isSyncing)
                  const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
