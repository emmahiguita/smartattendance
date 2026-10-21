// lib/features/attendance/presentation/widgets/hr_reports_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/presentation/admin_assignments.dart';
import 'export_preview_sheet.dart';

/// Pestaña 4 de RRHH: Reportes, Infraestructura de Geocercas y Política de Datos.
class HrReportsTab extends ConsumerStatefulWidget {
  const HrReportsTab({super.key});

  @override
  ConsumerState<HrReportsTab> createState() => _HrReportsTabState();
}

class _HrReportsTabState extends ConsumerState<HrReportsTab> {
  void _openExportReport() {
    final now = DateTime.now();
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportPreviewSheet(
        fechaDesde: now.subtract(const Duration(days: 30)),
        fechaHasta: now,
      ),
    ).then((path) {
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte exportado exitosamente:\n$path'),
            backgroundColor: AppColors.systemGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Tarjeta principal de Exportación
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.cBorder, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.file_download_outlined, color: Color(0xFF10B981), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reportes de Asistencia & Nómina',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: context.cTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Descarga consolidado de marcas, jornadas y horas extras',
                          style: TextStyle(fontSize: 12, color: context.cTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openExportReport,
                  icon: const Icon(Icons.table_chart_rounded, size: 16),
                  label: const Text('Generar y Exportar Reporte', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Infraestructura y Cuadrillas
        Text(
          'Infraestructura Operativa',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.cTextPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Configura geocercas en el mapa y equipos con supervisores autorizados',
          style: TextStyle(fontSize: 12, color: context.cTextSecondary),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: context.cSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.cBorder, width: 0.8),
          ),
          child: const AdminAssignments(),
        ),
        const SizedBox(height: 20),

        // 3. Tarjeta de Privacidad y Cumplimiento Legal
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.cBorder, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biometría y Ley 1581 de Protección de Datos',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.cTextPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Política de tratamiento activo para consentimientos biométricos',
                      style: TextStyle(fontSize: 11, color: context.cTextSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
