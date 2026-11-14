// ============================================================================
// ARCHIVO: hr_reports_tab.dart
// QUÉ HACE: Reúne sitios de trabajo, equipos y acceso al consolidado real.
// CÓMO FUNCIONA: Presenta secciones con divisores finos (0.5px) y fila compacta
//                para abrir la tabla consolidada de exportación a Excel o CSV.
// POR QUÉ: Elimina espacios muertos y tarjetas innecesarias (< 65 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/presentation/admin_assignments.dart';
import '../consolidated/consolidated_attendance_screen.dart';

class HrReportsTab extends ConsumerStatefulWidget {
  const HrReportsTab({super.key});
  @override
  ConsumerState<HrReportsTab> createState() => _HrReportsTabState();
}

class _HrReportsTabState extends ConsumerState<HrReportsTab> {
  void _openExportReport() {
    final now = DateTime.now();
    showAttendanceConsolidatedSheet(
      context,
      fechaDesde: now.subtract(const Duration(days: 30)),
      fechaHasta: now,
    ).then((path) {
      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reporte exportado:\n$path')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminAssignments(),
          const SizedBox(height: 12),
          Text(
            'REPORTES Y EXPORTACIÓN',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: context.cTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Divider(height: 1, thickness: 0.5, color: context.cBorder),
          InkWell(
            onTap: _openExportReport,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Icon(
                    Icons.table_view_outlined,
                    size: 20,
                    color: context.cTextSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consolidado de asistencia',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: context.cTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Revisa los registros antes de exportar a Excel o CSV.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.cTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 15,
                    color: context.cTextSecondary,
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: context.cBorder),
        ],
      );
}
