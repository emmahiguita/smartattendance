// lib/features/attendance/presentation/widgets/export_preview_sheet.dart
// ===================================================================
// BottomSheet de preview de exportación de asistencias.
// Muestra resumen, selector de formato, tabla con primeras filas,
// y botón de exportar.
// ===================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../viewmodels/export_preview_viewmodel.dart';

class ExportPreviewSheet extends ConsumerStatefulWidget {
  const ExportPreviewSheet({
    super.key,
    required this.fechaDesde,
    required this.fechaHasta,
  });

  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  @override
  ConsumerState<ExportPreviewSheet> createState() => _ExportPreviewSheetState();
}

class _ExportPreviewSheetState extends ConsumerState<ExportPreviewSheet> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ref.read(exportPreviewViewModelProvider.notifier).loadPreview(
          fechaDesde: widget.fechaDesde,
          fechaHasta: widget.fechaHasta,
        );
  }

  Future<void> _export() async {
    final path =
        await ref.read(exportPreviewViewModelProvider.notifier).executeExport(
              fechaDesde: widget.fechaDesde,
              fechaHasta: widget.fechaHasta,
            );
    if (path != null && mounted) {
      Navigator.of(context).pop(path);
    }
  }

  Future<void> _exportLocal() async {
    final path =
        await ref.read(exportPreviewViewModelProvider.notifier).executeExport(
              fechaDesde: widget.fechaDesde,
              fechaHasta: widget.fechaHasta,
              forceOfflineCsv: true,
            );
    if (path != null && mounted) {
      Navigator.of(context).pop(path);
    }
  }

  @override
  void dispose() {
    ref.read(exportPreviewViewModelProvider.notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exportPreviewViewModelProvider);
    final notifier = ref.read(exportPreviewViewModelProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: switch (state) {
            ExportPreviewIdle() ||
            ExportPreviewLoading() =>
              const Center(child: CircularProgressIndicator()),
            ExportPreviewError(:final message) => _buildError(message),
            ExportPreviewLoaded(:final data, :final format) => _buildLoaded(
                data,
                format,
                notifier,
                scrollCtrl,
              ),
            ExportPreviewExporting(:final format) => _buildExporting(format),
            ExportPreviewExported(:final filePath) => _buildExported(filePath),
          },
        );
      },
    );
  }

  Widget _buildLoaded(
    ExportPreviewData data,
    ExportFormat format,
    ExportPreviewViewModel notifier,
    ScrollController scrollCtrl,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Handle ──
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // ── Header ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Exportar Asistencias',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(),
        // ── Content ──
        Expanded(
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // Summary cards
              const SizedBox(height: 8),
              _buildSummaryRow(data),
              const SizedBox(height: 16),
              // Format selector
              _buildFormatSelector(format, notifier, data),
              const SizedBox(height: 16),
              // Preview table
              if (data.sample.isNotEmpty) ...[
                _buildSectionTitle(
                    'Vista previa (${data.sample.length} de ${data.totalRegistros} registros)'),
                const SizedBox(height: 8),
                _buildPreviewTable(data.sample),
              ] else ...[
                const SizedBox(height: 24),
                _buildEmptyState(),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
        // ── Bottom bar ──
        _buildBottomBar(data, format),
      ],
    );
  }

  Widget _buildSummaryRow(ExportPreviewData data) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryChip(
            icon: Icons.receipt_long,
            label: '${data.totalRegistros} registros',
            color: AppColors.primary),
        _SummaryChip(
            icon: Icons.people,
            label: '${data.empleadosUnicos} empleados',
            color: AppColors.accentIndigo),
        _SummaryChip(
            icon: Icons.login,
            label: '${data.entradas} entradas',
            color: AppColors.systemGreen),
        _SummaryChip(
            icon: Icons.logout,
            label: '${data.salidas} salidas',
            color: const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildFormatSelector(
    ExportFormat current,
    ExportPreviewViewModel notifier,
    ExportPreviewData data,
  ) {
    final xlsxSize = ExportPreviewViewModel.formatSize(data.tamanoEstimadoXlsx);
    final csvSize = ExportPreviewViewModel.formatSize(data.tamanoEstimadoCsv);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Formato de exportación'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _FormatCard(
                icon: Icons.table_chart,
                label: 'Excel',
                subtitle: 'Formato profesional (.xlsx)',
                size: xlsxSize,
                selected: current == ExportFormat.xlsx,
                onTap: () => notifier.setFormat(ExportFormat.xlsx, data),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FormatCard(
                icon: Icons.description,
                label: 'CSV',
                subtitle: 'Compatibilidad universal (.csv)',
                size: csvSize,
                selected: current == ExportFormat.csv,
                onTap: () => notifier.setFormat(ExportFormat.csv, data),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewTable(List<Map<String, dynamic>> sample) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.08),
          ),
          dataRowMinHeight: 40,
          dataRowMaxHeight: 48,
          headingTextStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
          dataTextStyle: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          columns: const [
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('Cédula'), numeric: true),
            DataColumn(label: Text('Cargo')),
            DataColumn(label: Text('Fecha')),
            DataColumn(label: Text('Entrada')),
            DataColumn(label: Text('Salida')),
            DataColumn(label: Text('Horas')),
            DataColumn(label: Text('Estado')),
          ],
          rows: sample.map((row) {
            final estado = row['estado'] as String? ?? '';
            Color chipColor;
            switch (estado) {
              case 'salida':
                chipColor = const Color(0xFF2563EB);
              case 'entrada':
                chipColor = AppColors.systemGreen;
              default:
                chipColor = AppColors.systemRed;
            }

            return DataRow(cells: [
              DataCell(Text(row['nombre'] as String? ?? '',
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              DataCell(Text(row['cedula'] as String? ?? '')),
              DataCell(Text((row['cargo'] as String? ?? ''),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              DataCell(Text(row['fecha'] as String? ?? '')),
              DataCell(Text(row['entrada'] as String? ?? '-')),
              DataCell(Text(row['salida'] as String? ?? '-')),
              DataCell(Text(row['horas'] as String? ?? '-')),
              DataCell(_EstadoChip(estado: estado, color: chipColor)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBottomBar(ExportPreviewData data, ExportFormat format) {
    final tieneDatos = data.totalRegistros > 0;
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: tieneDatos
                ? FilledButton.icon(
                    onPressed: _export,
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(
                      'Exportar '
                      '${ExportPreviewViewModel.formatSize(
                        format == ExportFormat.csv
                            ? data.tamanoEstimadoCsv
                            : data.tamanoEstimadoXlsx,
                      )}',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Sin datos para exportar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

  // ── Auxiliary states ─────────────────────────────────────────────

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.systemRed),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.systemRed,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const SizedBox(height: 8),
            Text('Puedes exportar un CSV con los datos locales sin conexión.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _exportLocal,
              icon: const Icon(Icons.save_alt, size: 18),
              label: const Text('Exportar CSV local'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.systemGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _load,
              child: const Text('Reintentar conexión'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExporting(ExportFormat format) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Generando archivo ${format.name.toUpperCase()}...',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Esto puede tomar unos segundos.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildExported(String filePath) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                size: 48, color: AppColors.systemGreen),
            const SizedBox(height: 16),
            const Text('Exportación completada',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text(filePath,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context, filePath),
              child: const Text('Listo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No hay registros en el período seleccionado.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700));
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label, subtitle, size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32, color: selected ? AppColors.primary : Colors.grey),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: selected ? AppColors.primary : null)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('~$size',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? AppColors.primary : Colors.grey.shade700)),
            ),
            if (selected) ...[
              const SizedBox(height: 8),
              const Icon(Icons.check_circle, size: 18, color: AppColors.primary),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado, required this.color});
  final String estado;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (estado) {
      'salida' => 'Finalizado',
      'entrada' => 'Pendiente',
      _ => 'Ausente',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
