// ============================================================================
// ARCHIVO: crew_members_list.dart
// QUÉ HACE: Despliega la lista interactiva de trabajadores adscritos a un equipo
//           (tanto en Nuevo Equipo como en Detalle de Cuadrilla).
// CÓMO FUNCIONA: Observa `localWorkersProvider` mediante Riverpod y delega
//                acciones a `CrewMemberActionSheet`.
// POR QUÉ: Permite configurar integrantes y puestos desde la creación (< 170 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/aqua_gloss_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/roles.dart';
import '../../domain/photo_record.dart';
import '../local_providers.dart';
import 'crew_member_action_sheet.dart';

class CrewMembersList extends ConsumerWidget {
  const CrewMembersList({
    super.key,
    required this.crewId,
    this.availablePositions = AppRoles.operationalPositions,
    this.pendingRolesByWorkerId = const {},
    this.onAddPendingMember,
    this.onRemovePendingMember,
  });

  final int? crewId;
  final List<String> availablePositions;
  final Map<int, String> pendingRolesByWorkerId;
  final void Function(LocalWorker worker, String role)? onAddPendingMember;
  final ValueChanged<int>? onRemovePendingMember;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (crewId == null && onAddPendingMember == null) return const SizedBox.shrink();
    final workersAsync = ref.watch(localWorkersProvider);

    return workersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('No se pudo cargar el personal asignado.', style: TextStyle(fontSize: 12, color: context.cTextSecondary)),
      ),
      data: (allWorkers) {
        final members = crewId != null
            ? allWorkers.where((w) => w.crewId == crewId).toList()
            : allWorkers
                .where((w) => pendingRolesByWorkerId.containsKey(w.id))
                .map((w) => LocalWorker(
                      id: w.id,
                      name: w.name,
                      document: w.document,
                      job: pendingRolesByWorkerId[w.id] ?? w.job,
                      crewId: w.crewId,
                      crewName: w.crewName,
                    ))
                .toList();

        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 6, top: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('PERSONAL DEL EQUIPO (${members.length})',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: context.cTextSecondary)),
              AquaGlossButton(
                icon: CupertinoIcons.plus,
                label: 'Agregar',
                compact: true,
                topColor: const Color(0xFF0FA3B1),
                bottomColor: const Color(0xFF007582),
                onPressed: () => CrewMemberActionSheet.showAddOptions(
                  context,
                  ref,
                  crewId,
                  allWorkers,
                  availablePositions: availablePositions,
                  onSelectPending: onAddPendingMember,
                  pendingWorkerIds: pendingRolesByWorkerId.keys.toSet(),
                ),
              ),
            ]),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.cSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.cBorder, width: 0.6),
            ),
            child: members.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Text(
                      'Sin personal adscrito a esta cuadrilla. Toca "Agregar" para seleccionar Operador, Colaborador u Operario.',
                      style: TextStyle(fontSize: 12.5, color: context.cTextSecondary),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: members.length,
                    separatorBuilder: (_, __) => Divider(height: 1, thickness: 0.5, indent: 48, color: context.cBorder),
                    itemBuilder: (context, index) => _buildMemberTile(context, ref, members[index]),
                  ),
          ),
        ]);
      },
    );
  }

  Widget _buildMemberTile(BuildContext context, WidgetRef ref, LocalWorker m) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Text(m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                style: TextStyle(color: context.cTextPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.cTextPrimary)),
              const SizedBox(height: 1),
              Text('${m.job} · C.C. ${m.document}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: context.cTextSecondary)),
            ]),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            minimumSize: Size.zero,
            onPressed: () {
              if (crewId != null) {
                CrewMemberActionSheet.confirmRemove(context, ref, m, availablePositions: availablePositions);
              } else {
                onRemovePendingMember?.call(m.id);
              }
            },
            child: const Icon(CupertinoIcons.minus_circle, size: 18, color: AppColors.systemRed),
          ),
        ]),
      );
}
