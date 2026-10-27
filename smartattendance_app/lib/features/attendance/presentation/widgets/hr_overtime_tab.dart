// ============================================================================
// ARCHIVO: hr_overtime_tab.dart
// QUÉ HACE: Bandeja ejecutiva de auditoría de Horas Extras estilo Apple iOS
//           con selector segmentado `CupertinoSlidingSegmentedControl` y aviso
//           formal de la regla del Administrador.
// CÓMO FUNCIONA: Las horas extras NO son marcadas por el empleado; se calculan
//                del horario asignado por el Administrador y se aprueban aquí.
// POR QUÉ: Cumple la regla de negocio y renueva la estética a iOS (< 155 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import 'hr_overtime_card.dart';

class HrOvertimeTab extends ConsumerStatefulWidget {
  const HrOvertimeTab({super.key});
  @override
  ConsumerState<HrOvertimeTab> createState() => _HrOvertimeTabState();
}

class _HrOvertimeTabState extends ConsumerState<HrOvertimeTab> {
  String _filter = 'pending';
  bool _busy = false;

  Future<void> _reviewDay(PhotoDay day, {required bool approve}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(localAdminStoreProvider).review(day, approve: approve);
      ref.invalidate(allOvertimeDaysProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(approve
              ? 'Horas extras aprobadas por el Administrador.'
              : 'Horas extras rechazadas.'),
          backgroundColor:
              approve ? AppColors.systemGreen : AppColors.systemRed,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e is FormatException ? e.message : e}'),
          backgroundColor: AppColors.systemRed,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _segLabel(String text, bool sel) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
            color: sel ? Colors.white : context.cTextPrimary,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final overtimeDaysAsync = ref.watch(allOvertimeDaysProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.cSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cBorder, width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.shield_lefthalf_fill,
                  size: 17, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Regla del Administrador: Las horas extras no se marcan; se calculan del horario asignado y se autorizan aquí.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: context.cTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CupertinoSlidingSegmentedControl<String>(
          groupValue: _filter,
          backgroundColor: context.cSurface,
          thumbColor: AppColors.primary,
          children: {
            'pending': _segLabel('Pendientes', _filter == 'pending'),
            'approved': _segLabel('Aprobadas', _filter == 'approved'),
            'rejected': _segLabel('Rechazadas', _filter == 'rejected'),
            'all': _segLabel('Todas', _filter == 'all'),
          },
          onValueChanged: (v) {
            if (v != null) setState(() => _filter = v);
          },
        ),
        const SizedBox(height: 12),
        overtimeDaysAsync.when(
          loading: () => const Center(
              child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CupertinoActivityIndicator())),
          error: (e, _) =>
              Center(child: Text('Error al cargar horas extras: $e')),
          data: (allDays) {
            final filtered = allDays.where((d) {
              final hasExtra = (d.totals.additional?.inSeconds ?? 0) > 0;
              final isApproved =
                  d.approvedSeconds != null && d.approvedSeconds! > 0;
              final isRejected =
                  d.approvedSeconds != null && d.approvedSeconds == 0;
              final isPending = d.approvedSeconds == null && hasExtra;
              return switch (_filter) {
                'pending' => isPending,
                'approved' => isApproved,
                'rejected' => isRejected,
                _ => true,
              };
            }).toList();

            if (filtered.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: context.cSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.cBorder, width: 0.5),
                ),
                child: Column(
                  children: [
                    Icon(
                      _filter == 'pending'
                          ? CupertinoIcons.checkmark_seal_fill
                          : CupertinoIcons.clock,
                      size: 32,
                      color: _filter == 'pending'
                          ? AppColors.systemGreen
                          : context.cTextSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _filter == 'pending'
                          ? 'Sin horas extras pendientes de revisión'
                          : 'No hay registros en esta categoría',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.cTextPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final day = filtered[index];
                return HrOvertimeCard(
                  day: day,
                  busy: _busy,
                  onApprove: () => _reviewDay(day, approve: true),
                  onReject: () => _reviewDay(day, approve: false),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
