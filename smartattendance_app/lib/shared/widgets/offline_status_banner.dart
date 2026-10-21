// lib/shared/widgets/offline_status_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../features/attendance/presentation/controllers/offline_sync_controller.dart';

/// ============================================================================
/// COMPONENTE: OfflineStatusBanner (Cápsula de Estado iOS Style)
/// ============================================================================
/// QUÉ HACE:
/// Muestra un banner flotante tipo "Dynamic Island" cuando hay desconexión
/// a internet o cuando existen marcas laborales pendientes de sincronización.
///
/// PARA QUÉ SIRVE:
/// Provee retroalimentación visual no invasiva, elegante y profesional
/// sobre el estado de la conexión de red y la cola de sincronización.
///
/// PRINCIPIOS SOLID:
/// - S (Single Responsibility): Exclusivamente notifica el estado de red y sincronización.
/// ============================================================================
class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(offlineSyncControllerProvider);

    if (syncState.isOnline && syncState.pendingCount == 0 && !syncState.isSyncing) {
      return const SizedBox.shrink();
    }

    Color tintColor;
    IconData iconData;
    String message;

    if (!syncState.isOnline) {
      tintColor = const Color(0xFFF59E0B); // Ámbar cálido iOS
      iconData = Icons.wifi_off_rounded;
      message = syncState.pendingCount > 0
          ? '${syncState.pendingCount} marcas guardadas localmente'
          : 'Modo sin conexión activa';
    } else if (syncState.isSyncing) {
      tintColor = AppColors.systemBlue;
      iconData = Icons.sync_rounded;
      message = 'Sincronizando ${syncState.pendingCount} marcas con servidor...';
    } else {
      tintColor = AppColors.systemGreen;
      iconData = Icons.cloud_upload_rounded;
      message = '${syncState.pendingCount} marcas pendientes por sincronizar';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (syncState.isOnline && syncState.pendingCount > 0) {
              ref.read(offlineSyncControllerProvider.notifier).triggerSync();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: context.cSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tintColor.withValues(alpha: 0.35), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (syncState.isSyncing)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(tintColor)),
                  )
                else
                  Icon(iconData, color: tintColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.cTextPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (syncState.isOnline && syncState.pendingCount > 0 && !syncState.isSyncing)
                  Icon(Icons.refresh_rounded, color: tintColor, size: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
