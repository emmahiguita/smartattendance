// ============================================================================
// ARCHIVO: consolidated_attendance_screen.dart
// CAPA: Presentation / Consolidated
// QUÉ HACE: Vista principal y administradora del Consolidado de Asistencias
//           con fondo negro puro (#000000), creación manual, edición y exportación.
// CÓMO FUNCIONA: Orquesta cabecera iOS, indicadores compactos, filtros, tabla
//                interactiva y modales de registro/edición sobre SQLite real.
// POR QUÉ: Garantiza que el Consolidado de Asistencias sea 100% funcional,
//          real y legible en modo oscuro (< 185 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'controllers/consolidated_attendance_controller.dart';
import 'models/consolidated_record.dart';
import 'widgets/consolidated_data_table.dart';
import 'widgets/consolidated_edit_sheet.dart';
import 'widgets/consolidated_export_dialog.dart';
import 'widgets/consolidated_filter_bar.dart';
import 'widgets/consolidated_header_bar.dart';
import 'widgets/consolidated_metrics_grid.dart';

Future<String?> showAttendanceConsolidatedSheet(
  BuildContext context, {
  DateTime? fechaDesde,
  DateTime? fechaHasta,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (ctx) => ConsolidatedAttendanceSheet(
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    ),
  );
}

class ConsolidatedAttendanceSheet extends ConsumerStatefulWidget {
  const ConsolidatedAttendanceSheet({
    super.key,
    this.fechaDesde,
    this.fechaHasta,
  });

  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  @override
  ConsumerState<ConsolidatedAttendanceSheet> createState() =>
      _ConsolidatedAttendanceSheetState();
}

class _ConsolidatedAttendanceSheetState
    extends ConsumerState<ConsolidatedAttendanceSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(consolidatedAttendanceControllerProvider.notifier).loadData(
              start: widget.fechaDesde,
              end: widget.fechaHasta,
            );
      }
    });
  }

  void _openEdit([ConsolidatedRecord? record]) {
    final state = ref.read(consolidatedAttendanceControllerProvider);
    final ctrl = ref.read(consolidatedAttendanceControllerProvider.notifier);

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.isDark ? const Color(0xFF111111) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ConsolidatedEditSheet(
        record: record,
        controller: ctrl,
        availableZones: state.availableZones,
      ),
    );
  }

  void _openExport() {
    final state = ref.read(consolidatedAttendanceControllerProvider);
    final ctrl = ref.read(consolidatedAttendanceControllerProvider.notifier);

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.isDark ? const Color(0xFF111111) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ConsolidatedExportDialog(state: state, controller: ctrl),
    ).then((path) {
      if (path != null && mounted) {
        Navigator.pop(context, path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(consolidatedAttendanceControllerProvider);
    final ctrl = ref.read(consolidatedAttendanceControllerProvider.notifier);
    final isDark = context.isDark;
    final size = MediaQuery.of(context).size;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: size.width > 900 ? 1080 : double.infinity,
          maxHeight: size.height * 0.94,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Scaffold(
            backgroundColor: isDark ? Colors.black : Colors.white,
            body: SafeArea(
              bottom: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConsolidatedHeaderBar(
                    state: state,
                    onClose: () => Navigator.pop(context),
                    onCreateTap: () => _openEdit(null),
                    onExportTap: _openExport,
                  ),
                  if (state.isLoading)
                    LinearProgressIndicator(
                      minHeight: 1.5,
                      color: context.cTextPrimary,
                      backgroundColor: Colors.transparent,
                    ),
                  if (state.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: AppColors.systemRed.withValues(alpha: 0.14),
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.systemRed,
                        ),
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => ctrl.loadData(
                        start: state.startDate,
                        end: state.endDate,
                      ),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ConsolidatedMetricsGrid(state: state),
                            ConsolidatedFilterBar(
                              state: state,
                              controller: ctrl,
                            ),
                            ConsolidatedDataTable(
                              state: state,
                              controller: ctrl,
                              onEditRecord: _openEdit,
                              onCreateRecord: () => _openEdit(null),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
