// ============================================================================
// ARCHIVO: export_preview_widgets.dart
// CAPA: Presentation / Widgets (Componentes Visuales de Previsualización)
// QUÉ HACE: Renderiza métricas (Jornadas, Personal, H. Extras), selector y tabla.
// CÓMO FUNCIONA: Tabla bidireccional con zona asignada, horas extras y estado sobrio.
// POR QUÉ: SRP de SOLID, < 180 líneas y diseño ejecutivo sin colores saturados.
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../viewmodels/export_preview_viewmodel.dart';

/// Fila de 4 tarjetas resumen con métricas clave del período.
class ExportSummaryRow extends StatelessWidget {
  const ExportSummaryRow({super.key, required this.data});
  final ExportPreviewData data;

  @override
  Widget build(BuildContext context) {
    final jor = data.totalJornadas > 0 ? data.totalJornadas : (data.totalRegistros ~/ 4);
    return Row(
      children: [
        _buildMetric(context, 'Jornadas', '$jor', Icons.event_available_rounded),
        const SizedBox(width: 8),
        _buildMetric(context, 'Personal', '${data.empleadosUnicos}', Icons.people_alt_rounded),
        const SizedBox(width: 8),
        _buildMetric(context, 'Entradas', '${data.entradas}', Icons.login_rounded),
        const SizedBox(width: 8),
        _buildMetric(context, 'H. Extras', data.horasExtrasTotal, Icons.more_time_rounded),
      ],
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value, IconData icon) {
    final isDark = context.isDark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.cBorder.withValues(alpha: 0.5), width: 0.6),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: context.cTextSecondary),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: context.cTextPrimary)),
            Text(label, style: TextStyle(fontSize: 10, color: context.cTextSecondary), maxLines: 1),
          ],
        ),
      ),
    );
  }
}

/// Selector de formato para exportar (.xlsx o .csv) con peso estimado de descarga.
class ExportFormatSelector extends StatelessWidget {
  const ExportFormatSelector({super.key, required this.current, required this.data, required this.onSelect});
  final ExportFormat current;
  final ExportPreviewData data;
  final ValueChanged<ExportFormat> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildTile(context, ExportFormat.xlsx, 'Excel (.xlsx)', Icons.table_chart_rounded, ExportPreviewViewModel.formatSize(data.tamanoEstimadoXlsx))),
        const SizedBox(width: 10),
        Expanded(child: _buildTile(context, ExportFormat.csv, 'CSV (.csv)', Icons.article_rounded, ExportPreviewViewModel.formatSize(data.tamanoEstimadoCsv))),
      ],
    );
  }

  Widget _buildTile(BuildContext context, ExportFormat format, String label, IconData icon, String size) {
    final selected = current == format;
    final isDark = context.isDark;
    return GestureDetector(
      onTap: () => onSelect(format),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A).withValues(alpha: 0.08))
              : context.cSurface,
          border: Border.all(
            color: selected ? (isDark ? Colors.white38 : const Color(0xFF0F172A)) : context.cBorder,
            width: selected ? 1.4 : 0.7,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: selected ? context.cTextPrimary : context.cTextSecondary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: context.cTextPrimary)),
                Text('~$size', style: TextStyle(fontSize: 10, color: context.cTextSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tabla interactiva con scroll horizontal y vertical con Zona y Horas Extras sobrias.
class ExportPreviewDataTable extends StatelessWidget {
  const ExportPreviewDataTable({super.key, required this.sample});
  final List<Map<String, dynamic>> sample;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: context.cSurface,
        border: Border.all(color: context.cBorder.withValues(alpha: 0.8)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            ),
            dataRowMinHeight: 34,
            dataRowMaxHeight: 40,
            columnSpacing: 16,
            horizontalMargin: 12,
            columns: const [
              DataColumn(label: Text('Colaborador', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
              DataColumn(label: Text('Cédula', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
              DataColumn(label: Text('Zona / Sede', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
              DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
              DataColumn(label: Text('Entrada', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
              DataColumn(label: Text('Salida', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
              DataColumn(label: Text('Horas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
              DataColumn(label: Text('H. Extras', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
              DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5))),
            ],
            rows: sample.map((row) {
              return DataRow(cells: [
                DataCell(Text('${row['nombre'] ?? ''}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.cTextPrimary))),
                DataCell(Text('${row['cedula'] ?? ''}', style: TextStyle(fontSize: 11, color: context.cTextPrimary))),
                DataCell(Text('${row['zona'] ?? 'Sede Principal'}', style: TextStyle(fontSize: 11, color: context.cTextPrimary))),
                DataCell(Text('${row['fecha'] ?? ''}', style: TextStyle(fontSize: 11, color: context.cTextSecondary))),
                DataCell(Text('${row['entrada'] ?? '-'}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.cTextPrimary))),
                DataCell(Text('${row['salida'] ?? '-'}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: context.cTextPrimary))),
                DataCell(Text('${row['horas'] ?? '-'}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.cTextPrimary))),
                DataCell(Text('${row['extras'] ?? '0h 00m'}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.cTextPrimary))),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.cBorder.withValues(alpha: 0.5), width: 0.6),
                  ),
                  child: Text(
                    '${row['estado'] ?? 'Cerrada'}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.cTextPrimary),
                  ),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
