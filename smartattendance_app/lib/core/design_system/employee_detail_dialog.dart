// ============================================================================
// ARCHIVO: employee_detail_dialog.dart
// QUÉ HACE: Modal de credencial corporativa 3D (`EmployeeCredentialCard`) y
//           estado laboral/asistencial del colaborador.
// CÓMO FUNCIONA: Muestra la tarjeta interactiva con código QR, estado de
//                contrato, estado de marcación de hoy y enlace directo a la
//                gestión de horarios/horas extras (`WorkerHrManagementSheet`).
// POR QUÉ: Cumple SRP (< 185 líneas) y diferencia estado contractual vs diario.
// ============================================================================

import 'package:flutter/material.dart';
import '../../features/attendance/presentation/widgets/worker_hr_management_sheet.dart';
import '../../features/photo_attendance/domain/photo_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'ios_floating_glass_sheet.dart';

class EmployeeDetailDialog extends StatelessWidget {
  final LocalWorker worker;
  final String attendanceStatusLabel;
  final Color attendanceStatusColor;
  final String? lastMarkTime;
  final VoidCallback? onRegisterTap;

  const EmployeeDetailDialog({
    super.key,
    required this.worker,
    required this.attendanceStatusLabel,
    required this.attendanceStatusColor,
    this.lastMarkTime,
    this.onRegisterTap,
  });

  static Future<void> show(
    BuildContext context, {
    required LocalWorker worker,
    required String attendanceStatusLabel,
    required Color attendanceStatusColor,
    String? lastMarkTime,
    VoidCallback? onRegisterTap,
  }) {
    return showIosFloatingGlassSheet<void>(
      context: context,
      title: 'Credencial y Estado',
      subtitle: worker.name,
      child: EmployeeDetailDialog(
        worker: worker,
        attendanceStatusLabel: attendanceStatusLabel,
        attendanceStatusColor: attendanceStatusColor,
        lastMarkTime: lastMarkTime,
        onRegisterTap: onRegisterTap,
      ),
    );
  }

  String _nextMarkLabel(String? lastMark) => switch (lastMark) {
        'entrada' => 'Inicio de almuerzo o Salida',
        'salida_almuerzo' => 'Regreso de almuerzo',
        'regreso_almuerzo' => 'Salida de jornada',
        'salida' => 'Entrada (Nueva jornada)',
        _ => 'Entrada de jornada',
      };

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              EmployeeCredentialCard(
                employeeName: worker.name,
                employeeId: worker.document,
                role: worker.job,
                heroTag: 'worker-detail-${worker.id}',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cBackgroundSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.cBorder.withValues(alpha: isDark ? 0.4 : 0.8),
                  ),
                ),
                child: Column(
                  children: [
                    _infoRow(
                      context,
                      'Estado contractual',
                      'EMPLEADO ACTIVO',
                      color: AppColors.systemGreen,
                    ),
                    const Divider(height: 16),
                    _infoRow(
                      context,
                      'Asistencia hoy',
                      attendanceStatusLabel.toUpperCase(),
                      color: attendanceStatusColor,
                    ),
                    const Divider(height: 16),
                    _infoRow(
                      context,
                      'Horario asignado',
                      worker.schedule != null
                          ? '${worker.schedule!.dailyMinutes ~/ 60}h diarias'
                          : 'Jornada Ordinaria (8h)',
                    ),
                    const SizedBox(height: 8),
                    _infoRow(
                      context,
                      'Siguiente hito',
                      _nextMarkLabel(worker.lastMark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  WorkerHrManagementSheet.show(context, worker: worker);
                },
                icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                label: const Text('Gestionar Equipo, Horario y Horas Extras'),
              ),
            ],
          ),
        );
  }

  Widget _infoRow(BuildContext context, String label, String value,
      {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: context.cTextSecondary, fontSize: 12.5),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: color ?? context.cTextPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
