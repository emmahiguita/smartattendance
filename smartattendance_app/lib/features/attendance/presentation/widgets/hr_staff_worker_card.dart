// ============================================================================
// ARCHIVO: hr_staff_worker_card.dart
// QUÉ HACE: Fila de colaborador estilo Apple iOS dentro del directorio de
//           Personal con avatar circular sobrio, estado actual, horario y QR.
// CÓMO FUNCIONA: Al tocar la fila abre `WorkerHrManagementSheet`; al tocar el
//                icono QR abre `EmployeeDetailDialog`.
// POR QUÉ: Sustituye tarjetas pesadas por filas iOS compactas (< 145 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Text(
                worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: context.cTextPrimary,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.cTextPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: context.cTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${rolePart}C.C. ${worker.document} · $scheduleText$crewPart',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.cTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
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
