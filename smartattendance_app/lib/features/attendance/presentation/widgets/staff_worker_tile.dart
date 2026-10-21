// lib/features/attendance/presentation/widgets/staff_worker_tile.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import 'staff_status_types.dart';

/// ============================================================================
/// COMPONENTE: StaffWorkerTile (Estilo iOS Grouped Cell)
/// ============================================================================
/// QUÉ HACE:
/// Muestra un colaborador individual con avatar, cargo, número de documento,
/// píldora de estado (chip compacto) y hora del último registro con formato tabular.
///
/// CÓMO FUNCIONA:
/// Diseñado como celda iOS con respuesta táctil InkWell y separador hairline
/// inferior de 0.5dp sangrado para alinear con el texto.
///
/// POR QUÉ:
/// Garantiza diseño limpio tipo iOS Settings/Contacts, cero saturación visual,
/// sin botones gigantes y legibilidad tipográfica profesional.
/// ============================================================================
class StaffWorkerTile extends StatelessWidget {
  const StaffWorkerTile({
    super.key,
    required this.worker,
    required this.status,
    required this.onTap,
    this.showDivider = true,
  });

  final LocalWorker worker;
  final StaffAttendanceStatus status;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial = worker.name.trim().isEmpty ? '?' : worker.name.trim()[0].toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: status.color.withValues(alpha: 0.12),
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: status.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.cTextPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          '${worker.job.isEmpty ? 'Colaborador' : worker.job} · C.C. ${worker.document}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: status.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.label,
                          style: TextStyle(
                            color: status.color,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (worker.lastMarkAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          ColombiaClock.hour(worker.lastMarkAt!),
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
                            fontSize: 10.5,
                            fontFeatures: AppDesignTokens.tabularFigures,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (showDivider)
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
