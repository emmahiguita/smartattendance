// ============================================================================
// ARCHIVO: consolidated_data_table.dart
// CAPA: Presentation / Consolidated / Widgets
// QUÉ HACE: Tabla interactiva profesional con scroll horizontal real y barra visual.
// CÓMO FUNCIONA: Despliega columnas con anchos definidos, Scrollbar con feedback y
//                botón de registro directo cuando aún no hay asistencias en el filtro.
// POR QUÉ: Permite navegar y editar la información completa sin recortes y con
//          estética iOS negra pura (< 200 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../controllers/consolidated_attendance_controller.dart';
import '../controllers/consolidated_attendance_state.dart';
import '../models/consolidated_record.dart';
import 'consolidated_table_row.dart';

class ConsolidatedDataTable extends StatefulWidget {
  const ConsolidatedDataTable({
    super.key,
    required this.state,
    required this.controller,
    required this.onEditRecord,
    this.onCreateRecord,
  });

  final ConsolidatedAttendanceState state;
  final ConsolidatedAttendanceController controller;
  final ValueChanged<ConsolidatedRecord> onEditRecord;
  final VoidCallback? onCreateRecord;

  @override
  State<ConsolidatedDataTable> createState() => _ConsolidatedDataTableState();
}

class _ConsolidatedDataTableState extends State<ConsolidatedDataTable> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// QUÉ HACE: Renderiza la tabla de datos o el estado vacío accionable.
  /// CÓMO: Envuelve `DataTable` en un `SingleChildScrollView` horizontal con `Scrollbar`.
  /// POR QUÉ: Evita desbordamientos horizontales en pantallas móviles estrechas.
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final records = widget.state.filteredRecords;

    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.doc_text_search, size: 40, color: context.cTextSecondary),
              const SizedBox(height: 12),
              Text(
                'No se encontraron asistencias en este filtro',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: context.cTextPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Ajusta el rango de fechas o registra una asistencia manual.',
                style: TextStyle(fontSize: 12, color: context.cTextSecondary),
                textAlign: TextAlign.center,
              ),
              if (widget.onCreateRecord != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: widget.onCreateRecord,
                  icon: const Icon(CupertinoIcons.add_circled, size: 16),
                  label: const Text('Registrar asistencia manual'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final isAllSelected = widget.state.selectedCount > 0 &&
        widget.state.selectedCount == widget.state.filteredRecords.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.cBorder,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 920),
            child: DataTable(
              showCheckboxColumn: false,
              headingRowHeight: 40,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 52,
              horizontalMargin: 12,
              columnSpacing: 16,
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF1F5F9),
              ),
              columns: [
                DataColumn(
                  label: SizedBox(
                    width: 30,
                    child: Checkbox(
                      value: isAllSelected,
                      tristate: widget.state.selectedCount > 0 && !isAllSelected,
                      onChanged: (_) => widget.controller.toggleSelectAll(),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
                _buildHeaderColumn('Colaborador', ConsolidatedSortColumn.colaborador, 165),
                _buildHeaderColumn('Cédula', null, 110),
                _buildHeaderColumn('Zona / Sede', ConsolidatedSortColumn.zona, 175),
                _buildHeaderColumn('Fecha', ConsolidatedSortColumn.fecha, 90),
                _buildHeaderColumn('Entrada', ConsolidatedSortColumn.entrada, 80),
                _buildHeaderColumn('Salida', ConsolidatedSortColumn.salida, 80),
                _buildHeaderColumn('Horas', ConsolidatedSortColumn.horas, 75),
                _buildHeaderColumn('H. Extras', ConsolidatedSortColumn.extras, 80),
                _buildHeaderColumn('Estado', null, 85),
                DataColumn(
                  label: SizedBox(
                    width: 44,
                    child: Text(
                      'Acción',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: context.cTextPrimary),
                    ),
                  ),
                ),
              ],
              rows: List.generate(records.length, (index) {
                final r = records[index];
                return ConsolidatedTableRow.build(
                  context: context,
                  record: r,
                  isSelected: widget.state.selectedIds.contains(r.journeyId),
                  isEven: index.isEven,
                  onToggleSelect: widget.controller.toggleRowSelection,
                  onEdit: widget.onEditRecord,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  /// QUÉ HACE: Construye una cabecera de columna ordenable con icono indicador.
  /// CÓMO: Evalúa si `sortCol` coincide con el orden activo en `widget.state`.
  /// POR QUÉ: Facilita ordenar por colaborador, sede, fecha, entrada, salida u horas.
  DataColumn _buildHeaderColumn(String title, ConsolidatedSortColumn? sortCol, double width) {
    final isSorted = sortCol != null && widget.state.sortColumn == sortCol;
    return DataColumn(
      label: SizedBox(
        width: width,
        child: InkWell(
          onTap: sortCol != null ? () => widget.controller.setSort(sortCol) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5, color: context.cTextPrimary),
              ),
              if (isSorted) ...[
                const SizedBox(width: 4),
                Icon(
                  widget.state.sortAscending ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down,
                  size: 11,
                  color: context.cTextPrimary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
