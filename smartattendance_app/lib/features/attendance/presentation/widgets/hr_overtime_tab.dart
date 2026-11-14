// ============================================================================
// ARCHIVO: hr_overtime_tab.dart
// QUÉ HACE: Bandeja ejecutiva de auditoría de Horas Extras estilo Apple iOS
//           sin tarjetas ni bordes azules, con selector segmentado neutro y
//           divisores finos compactos.
// CÓMO FUNCIONA: Las horas extras se calculan del horario asignado por el
//                Administrador y se aprueban o rechazan desde esta vista.
// POR QUÉ: Unifica la estética iOS profesional sin cajas redundantes (< 155 líneas).
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
            color: context.cTextPrimary,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final overtimeDaysAsync = ref.watch(allOvertimeDaysProvider);
    final isDark = context.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.shield_lefthalf_fill,
                size: 16,
                color: context.cTextSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Regla del Administrador: Las horas extras se calculan del horario asignado y se autorizan aquí.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.cTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        CupertinoSlidingSegmentedControl<String>(
          groupValue: _filter,
          backgroundColor:
              isDark ? const Color(0xFF121214) : const Color(0xFFF2F2F7),
          thumbColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
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
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 0.5, color: context.cBorder),
        overtimeDaysAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CupertinoActivityIndicator(),
            ),
          ),
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
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _filter == 'pending'
                          ? CupertinoIcons.checkmark_seal
                          : CupertinoIcons.clock,
                      size: 18,
                      color: context.cTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _filter == 'pending'
                            ? 'Sin horas extras pendientes de revisión'
                            : 'No hay registros en esta categoría',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.cTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final day in filtered)
                  HrOvertimeCard(
                    day: day,
                    busy: _busy,
                    onApprove: () => _reviewDay(day, approve: true),
                    onReject: () => _reviewDay(day, approve: false),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
