// ============================================================================
// ARCHIVO: crew_member_action_sheet.dart
// QUÉ HACE: Controladores y diálogos modales para agregar personal a una
//           cuadrilla asignando su puesto (`Operador`, `Colaborador`, `Operario`,
//           etc.), cambiarle el puesto o desvincularlo/eliminarlo.
// CÓMO FUNCIONA: Ejecuta `setWorkerCrew(..., role: selectedRole)` o `deleteWorker`
//                en `LocalAdminStore`, notificando a Riverpod en vivo.
// POR QUÉ: Permite seleccionar el puesto laboral al vincular personal al equipo (< 180 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/roles.dart';
import '../../domain/photo_record.dart';
import '../local_providers.dart';
import '../worker_dialog.dart';

class CrewMemberActionSheet {
  /// QUÉ HACE: Muestra opciones para cambiar puesto, desvincular o eliminar un trabajador.
  static Future<void> confirmRemove(
    BuildContext context,
    WidgetRef ref,
    LocalWorker worker, {
    List<String> availablePositions = AppRoles.operationalPositions,
  }) async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('${worker.name} · ${worker.job}'),
        message: const Text('Selecciona el puesto a aplicar o la acción sobre este integrante:'),
        actions: [
          for (final pos in availablePositions)
            if (pos != worker.job)
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(ctx, 'role:$pos'),
                child: Text('Cambiar puesto a $pos'),
              ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx, 'unbind'),
            child: const Text('Desvincular de este equipo'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text('Eliminar trabajador por error'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ),
    );

    if (action == null || !context.mounted) return;

    final store = ref.read(localAdminStoreProvider);
    if (action.startsWith('role:')) {
      final newRole = action.substring(5);
      await store.setWorkerCrew(worker.id, worker.crewId, role: newRole);
    } else if (action == 'unbind') {
      await store.setWorkerCrew(worker.id, null);
    } else if (action == 'delete') {
      await store.deleteWorker(worker.id);
    }
    ref.invalidate(localWorkersProvider);
  }

  /// QUÉ HACE: Abre selector de puesto (`Operador`, `Colaborador`, `Operario`, etc.).
  static Future<String?> pickPositionForWorker(
    BuildContext context,
    LocalWorker worker,
    List<String> positions,
  ) async {
    final opts = positions.isNotEmpty ? positions : AppRoles.operationalPositions;
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('Puesto para ${worker.name}'),
        message: const Text('Selecciona el puesto que desempeñará en el equipo:'),
        actions: [
          for (final pos in opts)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, pos),
              child: Text(
                pos == worker.job ? '$pos (Puesto actual)' : pos,
                style: TextStyle(
                  fontWeight: pos == worker.job ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  /// QUÉ HACE: Abre el modal para vincular existentes (eligiendo su puesto) o registrar uno nuevo.
  static Future<void> showAddOptions(
    BuildContext context,
    WidgetRef ref,
    int? crewId,
    List<LocalWorker> allWorkers, {
    List<String> availablePositions = AppRoles.operationalPositions,
    void Function(LocalWorker worker, String role)? onSelectPending,
    Set<int> pendingWorkerIds = const {},
  }) async {
    final available = allWorkers.where((w) {
      if (crewId != null) return w.crewId != crewId;
      return !pendingWorkerIds.contains(w.id);
    }).toList();

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Agregar Integrante y Puesto al Equipo'),
        message: Text(available.isEmpty
            ? 'Registra un nuevo colaborador o selecciona uno existente:'
            : 'Selecciona un colaborador para asignarle puesto en este equipo:'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              WorkerDialog.open(context)
                  .then((_) => ref.invalidate(localWorkersProvider));
            },
            child: const Text('Registrar nuevo colaborador / operario', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          for (final w in available)
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.pop(ctx);
                final role = await pickPositionForWorker(context, w, availablePositions);
                if (role == null || !context.mounted) return;
                if (crewId != null) {
                  await ref.read(localAdminStoreProvider).setWorkerCrew(w.id, crewId, role: role);
                  ref.invalidate(localWorkersProvider);
                } else {
                  onSelectPending?.call(w, role);
                }
              },
              child: Text('${w.name} · ${w.job} (CC ${w.document})', style: const TextStyle(fontSize: 14)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }
}
