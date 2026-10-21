// lib/features/attendance/presentation/widgets/hr_overtime_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../../photo_attendance/presentation/local_providers.dart';

/// Pestaña 3 de RRHH: Bandeja Global de Horas Extras y Auditoría de Tiempo Adicional.
class HrOvertimeTab extends ConsumerStatefulWidget {
  const HrOvertimeTab({super.key});

  @override
  ConsumerState<HrOvertimeTab> createState() => _HrOvertimeTabState();
}

class _HrOvertimeTabState extends ConsumerState<HrOvertimeTab> {
  String _filter = 'pending'; // pending, approved, rejected, all
  bool _busy = false;

  Future<void> _reviewDay(PhotoDay day, {required bool approve}) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Aprobar Horas Extras' : 'Rechazar Horas Extras'),
        content: Text(
          approve
              ? '¿Deseas autorizar el tiempo adicional calculado (${_formatDuration(day.totals.additional ?? Duration.zero)}) para ${day.worker.name}?\n\nLa aprobación quedará registrada en la auditoría con tu firma.'
              : '¿Deseas rechazar el tiempo adicional para ${day.worker.name}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: approve ? AppColors.systemGreen : Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(approve ? 'Aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final store = ref.read(localAdminStoreProvider);
      await store.review(day, approve: approve);
      ref.invalidate(allOvertimeDaysProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Horas extras aprobadas exitosamente.' : 'Horas extras rechazadas.'),
            backgroundColor: approve ? AppColors.systemGreen : Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e is FormatException ? e.message : e}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    final overtimeDaysAsync = ref.watch(allOvertimeDaysProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filtro superior por estado de aprobación
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('Pendientes', 'pending'),
              const SizedBox(width: 8),
              _filterChip('Aprobadas', 'approved'),
              const SizedBox(width: 8),
              _filterChip('Rechazadas', 'rejected'),
              const SizedBox(width: 8),
              _filterChip('Todas', 'all'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        overtimeDaysAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(child: Text('Error al cargar horas extras: $e')),
          data: (allDays) {
            final filtered = allDays.where((d) {
              final isApproved = d.approvedSeconds != null && d.approvedSeconds! > 0;
              final isRejected = d.approvedSeconds != null && d.approvedSeconds == 0;
              final isPending = d.approvedSeconds == null && d.totals.additional != null;

              switch (_filter) {
                case 'pending':
                  return isPending;
                case 'approved':
                  return isApproved;
                case 'rejected':
                  return isRejected;
                case 'all':
                default:
                  return true;
              }
            }).toList();

            if (filtered.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(28),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: context.cSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.cBorder),
                ),
                child: Column(
                  children: [
                    Icon(
                      _filter == 'pending' ? Icons.task_alt_rounded : Icons.history_toggle_off_rounded,
                      size: 44,
                      color: _filter == 'pending' ? AppColors.systemGreen : context.cTextSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _filter == 'pending'
                          ? 'Todo al día en Horas Extras'
                          : 'No hay jornadas en esta categoría',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.cTextPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _filter == 'pending'
                          ? 'No hay jornadas adicionales pendientes de revisión por el administrador.'
                          : 'Cambia el filtro para ver otras jornadas.',
                      style: TextStyle(fontSize: 12, color: context.cTextSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final day = filtered[index];
                return _buildOvertimeCard(day);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundColor: context.cSurface,
      side: BorderSide(color: isSelected ? AppColors.primary : context.cBorder, width: isSelected ? 1.2 : 0.8),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }

  Widget _buildOvertimeCard(PhotoDay day) {
    final isPending = day.approvedSeconds == null && day.totals.additional != null;
    final isApproved = day.approvedSeconds != null && day.approvedSeconds! > 0;

    final additional = day.totals.additional ?? Duration.zero;
    final schedule = day.schedule;
    final scheduleLabel = schedule?.shiftName ?? schedule?.timeWindowFormatted ?? 'Jornada asignada';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
              : context.cBorder,
          width: isPending ? 1.2 : 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la tarjeta
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isPending
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                    : (isApproved ? AppColors.systemGreen.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.12)),
                child: Icon(
                  isPending
                      ? Icons.more_time_rounded
                      : (isApproved ? Icons.check_circle_outline_rounded : Icons.cancel_outlined),
                  size: 18,
                  color: isPending
                      ? const Color(0xFFD97706)
                      : (isApproved ? AppColors.systemGreen : Colors.red),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.worker.name,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: context.cTextPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${day.worker.job} · Fecha: ${ColombiaClock.day(day.worker.capturedAt)}',
                      style: TextStyle(fontSize: 11.5, color: context.cTextSecondary),
                    ),
                  ],
                ),
              ),
              // Estado badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                      : (isApproved ? AppColors.systemGreen.withValues(alpha: 0.12) : Colors.red.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPending ? 'Pendiente' : (isApproved ? 'Aprobada' : 'Rechazada'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isPending
                        ? const Color(0xFFD97706)
                        : (isApproved ? AppColors.systemGreen : Colors.red),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Desglose de horas
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.cBorder.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _timeCol('Pactado', scheduleLabel),
                Container(width: 1, height: 28, color: context.cBorder),
                _timeCol(
                  'Laborado',
                  day.totals.worked != null
                      ? ColombiaClock.duration(day.totals.worked!)
                      : '--:--:--',
                ),
                Container(width: 1, height: 28, color: context.cBorder),
                _timeCol('Extra', '+${_formatDuration(additional)}', isHighlight: true),
              ],
            ),
          ),

          if (day.reviewNote != null && day.reviewNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Nota: ${day.reviewNote}',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: context.cTextSecondary),
            ),
          ],

          // Acciones de revisión si está pendiente
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _reviewDay(day, approve: false),
                    icon: const Icon(Icons.close_rounded, size: 15, color: Colors.red),
                    label: const Text('Rechazar', style: TextStyle(fontSize: 12, color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 0.8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _reviewDay(day, approve: true),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Aprobar Extra', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.systemGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _timeCol(String title, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 10.5, color: context.cTextSecondary)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isHighlight ? const Color(0xFFD97706) : context.cTextPrimary,
          ),
        ),
      ],
    );
  }
}
