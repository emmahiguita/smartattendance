// ============================================================================
// ARCHIVO: worker_hr_overtime_section.dart
// QUÉ HACE: Renderiza el bloque de control y liquidación de horas extras para
//           la última jornada registrada de un colaborador.
// CÓMO FUNCIONA: Calcula mediante `JourneyReport.labels(day)` el tiempo
//                laborado real frente a la jornada pactada y expone botones
//                exclusivos para el Administrador (Aplicar horario / Aprobar /
//                Rechazar tiempo adicional).
// POR QUÉ: Desacopla la lógica de liquidación de `WorkerHrManagementSheet`
//          para mantener ambos archivos < 200 líneas (SRP).
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/journey_report.dart';
import '../../../photo_attendance/domain/photo_record.dart';

class WorkerHrOvertimeSection extends StatelessWidget {
  final PhotoDay? latestDay;
  final bool loading;
  final bool reviewing;
  final bool isDark;
  final VoidCallback onApplySchedule;
  final ValueChanged<bool> onReviewOvertime;

  const WorkerHrOvertimeSection({
    super.key,
    required this.latestDay,
    required this.loading,
    required this.reviewing,
    required this.isDark,
    required this.onApplySchedule,
    required this.onReviewOvertime,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final day = latestDay;
    if (day == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          'Sin registros de jornada reciente para este colaborador.',
          style: TextStyle(fontSize: 12, color: context.cTextSecondary),
        ),
      );
    }

    final values = JourneyReport.labels(day);
    final worked = values['Tiempo trabajado'] ?? '0h';
    final additional = values['Adicional por revisar'] ?? '0h';
    final approved = values['Adicional aprobado'] ?? '0h';
    final hasOvertime =
        additional.isNotEmpty && additional != '0h 0m' && additional != '0m';
    final isApproved = day.approvedSeconds != null && day.approvedSeconds! > 0;

    final badgeColor = isApproved
        ? AppColors.systemGreen
        : (hasOvertime ? AppColors.systemOrange : AppColors.primary);
    final badgeText = isApproved
        ? 'Extras aprobadas'
        : (hasOvertime ? 'Adicional por aprobar' : 'Jornada ordinaria');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Jornada: ${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.cTextSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _row(context, 'Tiempo laborado total', worked),
        const SizedBox(height: 5),
        _row(context, 'Tiempo adicional (Horas extras)', additional),
        if (isApproved) ...[
          const SizedBox(height: 5),
          _row(
            context,
            'Autorizado por Administrador',
            '$approved (${day.reviewedBy ?? 'Admin'})',
          ),
        ],
        const SizedBox(height: 10),
        if (day.schedule == null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: reviewing ? null : onApplySchedule,
              icon: const Icon(Icons.link_rounded, size: 16),
              label: const Text(
                'Vincular Jornada Pactada a este registro',
                style: TextStyle(fontSize: 12),
              ),
            ),
          )
        else if (hasOvertime && !isApproved)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: reviewing ? null : () => onReviewOvertime(false),
                  icon: const Icon(Icons.close_rounded,
                      size: 15, color: AppColors.systemRed),
                  label: const Text(
                    'Rechazar',
                    style: TextStyle(fontSize: 12, color: AppColors.systemRed),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: reviewing ? null : () => onReviewOvertime(true),
                  icon: const Icon(Icons.check_rounded, size: 15),
                  label: const Text(
                    'Aprobar Extras',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.systemGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: context.cTextSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: context.cTextPrimary,
          ),
        ),
      ],
    );
  }
}
