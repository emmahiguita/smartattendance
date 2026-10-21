// lib/features/attendance/presentation/widgets/admin_quick_actions.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../qr/presentation/widgets/generate_qr_dialog.dart';
import '../viewmodels/export_preview_viewmodel.dart';
import 'dashboard_action_card.dart';
import 'export_preview_sheet.dart';

/// ============================================================================
/// COMPONENTE: AdminQuickActions
/// ============================================================================
/// QUÉ HACE:
/// Despliega las herramientas administrativas exclusivas en el Dashboard:
/// - Asistencia de hoy (monitoreo de empleados en tiempo real)
/// - Exportación de reportes a Excel/CSV
/// - Generador de códigos QR corporativos para empleados
///
/// PRINCIPIOS SOLID APLICADOS:
/// - S (Single Responsibility): Gestiona exclusivamente los accesos de administradores.
/// ============================================================================
class AdminQuickActions extends ConsumerWidget {
  final bool isLandscape;

  const AdminQuickActions({super.key, required this.isLandscape});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Panel Administrador',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: context.cTextPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        DashboardActionCard(
          title: 'Asistencia de hoy',
          subtitle: 'Consulta llegadas, retrasos y pendientes',
          icon: Icons.groups_rounded,
          accentColor: const Color(0xFF6366F1),
          isRowLayout: true,
          onTap: () => context.push(AppRoutes.employeeToday),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: isLandscape ? 64 : 112,
                child: DashboardActionCard(
                  title: 'Exportar Excel',
                  subtitle: 'Reporte completo',
                  icon: Icons.download_rounded,
                  accentColor: const Color(0xFF059669),
                  isRowLayout: isLandscape,
                  onTap: () => _exportExcel(context, ref),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: isLandscape ? 64 : 112,
                child: DashboardActionCard(
                  title: 'Generar QR',
                  subtitle: 'Para empleados',
                  icon: Icons.qr_code_rounded,
                  accentColor: const Color(0xFF7C3AED),
                  isRowLayout: isLandscape,
                  onTap: () => showGenerateQrDialog(context, ref),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    if (kIsWeb) return;
    final path = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          const ExportPreviewSheet(fechaDesde: null, fechaHasta: null),
    );
    if (path != null && context.mounted) {
      ref.read(exportPreviewViewModelProvider.notifier).reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Reporte exportado:\n$path'),
            backgroundColor: AppColors.systemGreen),
      );
    }
  }
}
