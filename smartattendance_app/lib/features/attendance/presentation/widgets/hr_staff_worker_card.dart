// ============================================================================
// ARCHIVO: hr_staff_worker_card.dart
// QUÉ HACE: Fila de colaborador estilo Apple iOS Inset Grouped dentro del
//           directorio de Personal con avatar circular sobrio, estado actual,
//           horario pactado y botón de credencial QR.
// CÓMO FUNCIONA: Al tocar la fila abre la ventana flotante `WorkerHrManagementSheet`;
//                al tocar el icono QR abre `EmployeeDetailDialog`.
// POR QUÉ: Sustituye tarjetas pesadas separadas por filas iOS limpias (< 150 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import 'staff_status_types.dart';
import 'worker_hr_management_sheet.dart';

class HrStaffWorkerCard extends StatelessWidget {
  final LocalWorker worker;
  final StaffAttendanceStatus status;

  const HrStaffWorkerCard({
    super.key,
    required this.worker,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final hasSchedule = worker.schedule != null;
    final scheduleText = hasSchedule
        ? (worker.schedule!.shiftName ?? worker.schedule!.timeWindowFormatted)
        : 'Sin horario';
    final rolePart =
        worker.job.trim().isNotEmpty ? '${worker.job.trim()} · ' : '';
    final crewPart =
        (worker.crewName != null && worker.crewName!.trim().isNotEmpty)
            ? ' · ${worker.crewName}'
            : '';

    return InkWell(
      onTap: () => WorkerHrManagementSheet.show(context, worker: worker),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Text(
                worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          worker.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: context.cTextPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: context.cTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${rolePart}C.C. ${worker.document} · $scheduleText$crewPart',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.cTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => EmployeeDetailDialog.show(
                context,
                worker: worker,
                attendanceStatusLabel: status.label,
                attendanceStatusColor: status.color,
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  CupertinoIcons.qrcode,
                  size: 18,
                  color: context.cTextSecondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: context.cTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
