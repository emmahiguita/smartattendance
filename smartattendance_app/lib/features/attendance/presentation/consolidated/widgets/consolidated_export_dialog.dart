// ============================================================================
// ARCHIVO: consolidated_export_dialog.dart
// CAPA: Presentation / Consolidated / Widgets
// QUÉ HACE: Panel modal iOS para exportación contextual en Excel (.xlsx) o CSV.
// CÓMO FUNCIONA: Ofrece selector de formato Cupertino y alcance con cálculo en vivo.
// POR QUÉ: Sustituye botones estáticos gigantes por un flujo compacto < 185 líneas.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../viewmodels/export_preview_state.dart';
import '../controllers/consolidated_attendance_controller.dart';
import '../controllers/consolidated_attendance_state.dart';

class ConsolidatedExportDialog extends StatefulWidget {
  const ConsolidatedExportDialog({super.key, required this.state, required this.controller});
  final ConsolidatedAttendanceState state;
  final ConsolidatedAttendanceController controller;

  @override
  State<ConsolidatedExportDialog> createState() => _ConsolidatedExportDialogState();
}

class _ConsolidatedExportDialogState extends State<ConsolidatedExportDialog> {
  ExportFormat _format = ExportFormat.xlsx;
  late ExportScope _scope;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _scope = widget.state.selectedCount > 0
        ? ExportScope.selected
        : (widget.state.hasActiveFilters ? ExportScope.filtered : ExportScope.all);
  }

  int _rowCount(ExportScope s) {
    switch (s) {
      case ExportScope.all: return widget.state.allRecords.length;
      case ExportScope.filtered: return widget.state.filteredRecords.length;
      case ExportScope.selected: return widget.state.selectedCount;
    }
  }

  Future<void> _runExport() async {
    setState(() => _isExporting = true);
    final path = await widget.controller.export(format: _format, scope: _scope);
    if (mounted) {
      setState(() => _isExporting = false);
      if (path != null) Navigator.pop(context, path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rowCount(_scope);
    final estKb = _format == ExportFormat.xlsx ? (rows * 180 + 4096) ~/ 1024 : (rows * 110 + 256) ~/ 1024;
    final isDark = context.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Exportar Asistencias', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: context.cTextPrimary)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(CupertinoIcons.clear_circled_solid, size: 20),
                color: context.cTextSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlidingSegmentedControl<ExportFormat>(
              groupValue: _format,
              thumbColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              children: const {
                ExportFormat.xlsx: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Excel (.xlsx)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                ExportFormat.csv: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('CSV (.csv)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
              },
              onValueChanged: (f) { if (f != null) setState(() => _format = f); },
            ),
          ),
          const SizedBox(height: 16),
          Text('Alcance de exportación', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.cTextSecondary)),
          const SizedBox(height: 6),
          _tile(ExportScope.all, 'Todos los registros', '${widget.state.allRecords.length} jornadas consolidadas', CupertinoIcons.square_stack_3d_up),
          _tile(ExportScope.filtered, 'Registros filtrados', '${widget.state.filteredRecords.length} que coinciden con filtros', CupertinoIcons.line_horizontal_3_decrease_circle),
          _tile(ExportScope.selected, 'Selección actual', widget.state.selectedCount > 0 ? '${widget.state.selectedCount} seleccionadas' : 'Ninguna seleccionada', CupertinoIcons.checkmark_square, enabled: widget.state.selectedCount > 0),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(color: context.cBorder.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total filas: $rows', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.cTextPrimary)),
                Text('Tamaño: ~$estKb KB', style: TextStyle(fontSize: 12, color: context.cTextSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: rows > 0 && !_isExporting ? _runExport : null,
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isExporting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(CupertinoIcons.arrow_down_doc_fill, size: 16),
            label: Text(_isExporting ? 'Generando...' : 'Exportar ${_format.label} ($rows)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }

  Widget _tile(ExportScope scope, String label, String subtitle, IconData icon, {bool enabled = true}) {
    final isSelected = _scope == scope;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: InkWell(
        onTap: enabled ? () => setState(() => _scope = scope) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Icon(isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle, size: 18, color: isSelected ? context.cTextPrimary : context.cTextSecondary),
              const SizedBox(width: 10),
              Icon(icon, size: 16, color: isSelected ? context.cTextPrimary : context.cTextSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.cTextPrimary)),
                    Text(subtitle, style: TextStyle(fontSize: 10.5, color: context.cTextSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
