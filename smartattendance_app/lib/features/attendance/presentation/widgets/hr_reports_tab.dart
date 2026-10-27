// ============================================================================
// ARCHIVO: hr_reports_tab.dart
// QUÉ HACE: Pestaña 4 de Gestión RRHH ("Zonas") que consolida la configuración
//           de Geocercas GPS (`work_zones`), Equipos de Trabajo (`crews`),
//           la previsualización tabular de datos antes de exportar y el estado
//           de la conexión a Google Sheets / Excel.
// CÓMO FUNCIONA: Integra `AdminAssignments` con tipografía ejecutiva y lanza
//                `ExportPreviewSheet` con estilo corporativo unificado.
// POR QUÉ: Permite al administrador auditar la tabla antes de exportar y
//          conocer el estado de la integración de hojas de cálculo (< 175 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/presentation/admin_assignments.dart';
import 'export_preview_sheet.dart';

class HrReportsTab extends ConsumerStatefulWidget {
  const HrReportsTab({super.key});

  @override
  ConsumerState<HrReportsTab> createState() => _HrReportsTabState();
}

class _HrReportsTabState extends ConsumerState<HrReportsTab> {
  void _openExportReport() {
    final now = DateTime.now();
    showIosFloatingGlassSheet<String>(
      context: context,
      title: 'Consolidado de Asistencias',
      subtitle: 'Vista previa de la tabla y exportación en XLSX / CSV / Sheets',
      maxHeightFactor: 0.88,
      child: ExportPreviewSheet(
        fechaDesde: now.subtract(const Duration(days: 30)),
        fechaHasta: now,
      ),
    ).then((path) {
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte exportado:\n$path'),
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
        const AdminAssignments(),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.cSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cBorder, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: context.cBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.cBorder, width: 0.8),
                    ),
                    child: Icon(
                      Icons.table_view_outlined,
                      color: context.cTextSecondary,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consolidado de Asistencia y Nómina',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: context.cTextPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Revisa la información en la tabla antes de exportar a Excel o CSV',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.cTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openExportReport,
                  icon: const Icon(Icons.preview_rounded, size: 16),
                  label: const Text(
                    'Ver Tabla y Previsualizar Exportación',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.cSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cBorder, width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.systemGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.cloud_sync_outlined,
                  color: AppColors.systemGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conexión Google Sheets Cloud',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.cTextPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Integración API gspread lista (Asistencias_SmartAttendance)',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: context.cTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
