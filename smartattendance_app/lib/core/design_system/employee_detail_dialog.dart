import 'package:flutter/material.dart';
import '../../features/attendance/presentation/widgets/worker_hr_management_sheet.dart';
import '../../features/photo_attendance/domain/photo_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// MODAL: EmployeeDetailDialog
/// ============================================================================
/// Ficha técnica y credencial del empleado.
/// Diferencia explícitamente:
/// - Estado laboral (Relación contractual: ACTIVO / INACTIVO)
/// - Estado de asistencia (Presencia actual: EN JORNADA, SIN ENTRADA, etc.)
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
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmployeeDetailDialog(
        worker: worker,
        attendanceStatusLabel: attendanceStatusLabel,
        attendanceStatusColor: attendanceStatusColor,
        lastMarkTime: lastMarkTime,
        onRegisterTap: onRegisterTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: context.cSurface,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusPanelLarge),
          border: Border.all(color: context.cBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Tirador superior modal
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: context.cBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Credencial visual con soporte 3D Flip
                  EmployeeCredentialCard(
                    employeeName: worker.name,
                    employeeId: worker.document,
                    role: worker.job,
                    heroTag: 'worker-detail-${worker.id}',
                  ),
                  const SizedBox(height: AppDesignTokens.space20),

                  // Diferenciación visual de estados
                  Container(
                    padding: const EdgeInsets.all(AppDesignTokens.space16),
                    decoration: BoxDecoration(
                      color: context.cBackgroundSecondary,
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
                      border: Border.all(
                        color: context.cBorder.withValues(alpha: isDark ? 0.4 : 0.8),
                        width: AppDesignTokens.borderWidth,
                      ),
                    ),
                    child: Column(
                      children: [
                        _statusRow(
                          context,
                          title: 'Estado laboral (Contrato)',
                          badgeText: 'EMPLEADO ACTIVO',
                          badgeBg: AppColors.systemGreen.withValues(alpha: 0.12),
                          badgeFg: AppColors.systemGreen,
                          icon: Icons.work_outline_rounded,
                        ),
                        const Divider(height: 20),
                        _statusRow(
                          context,
                          title: 'Estado de asistencia hoy',
                          badgeText: attendanceStatusLabel.toUpperCase(),
                          badgeBg: attendanceStatusColor.withValues(alpha: 0.12),
                          badgeFg: attendanceStatusColor,
                          icon: Icons.access_time_rounded,
                          detail: lastMarkTime != null ? 'Última marca: $lastMarkTime' : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDesignTokens.space16),

                  // Información de jornada y horario
                  Text(
                    'Horario y cuadrilla',
                    style: AppDesignTokens.title(color: context.cTextPrimary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(AppDesignTokens.space16),
                    decoration: BoxDecoration(
                      color: context.cSurface,
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
                      border: Border.all(
                        color: context.cBorder.withValues(alpha: isDark ? 0.4 : 0.8),
                        width: AppDesignTokens.borderWidth,
                      ),
                    ),
                    child: Column(
                      children: [
                        _infoItem(
                          context,
                          'Horario asignado',
                          worker.schedule != null
                              ? '${worker.schedule!.dailyMinutes ~/ 60}h diarias'
                              : 'Jornada Ordinaria (8h)',
                        ),
                        const SizedBox(height: 8),
                        _infoItem(
                          context,
                          'Siguiente marca recomendada',
                          _nextMarkLabel(worker.lastMark),
                        ),
                        const SizedBox(height: 8),
                        _infoItem(
                          context,
                          'Área / Cuadrilla',
                          worker.job.isNotEmpty ? worker.job : 'General',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppDesignTokens.space24),

                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, AppDesignTokens.minTouchTargetSize),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusButton),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      WorkerHrManagementSheet.show(context, worker: worker);
                    },
                    icon: const Icon(Icons.manage_accounts_rounded),
                    label: const Text('Gestión de Horario y Horas Extras (RRHH)'),
                  ),
                  const SizedBox(height: 10),

                  if (onRegisterTap != null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, AppDesignTokens.minTouchTargetSize),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDesignTokens.radiusButton),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onRegisterTap!();
                      },
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: const Text('Registrar asistencia'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _statusRow(
    BuildContext context, {
    required String title,
    required String badgeText,
    required Color badgeBg,
    required Color badgeFg,
    required IconData icon,
    String? detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.cTextSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.cTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeFg,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (detail != null) ...[
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(
                    color: context.cTextSecondary,
                    fontSize: 12,
                    fontFeatures: AppDesignTokens.tabularFigures,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoItem(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.cTextSecondary, fontSize: 13)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: context.cTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _nextMarkLabel(String? lastMark) {
    return switch (lastMark) {
      'entrada' => 'Inicio de almuerzo o Salida',
      'salida_almuerzo' => 'Regreso de almuerzo',
      'regreso_almuerzo' => 'Salida de jornada',
      'salida' => 'Entrada (Nueva jornada)',
      _ => 'Entrada de jornada',
    };
  }
}
