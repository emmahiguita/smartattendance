// lib/features/attendance/presentation/widgets/export_preview_sheet.dart
// ============================================================================
// ARCHIVO: export_preview_sheet.dart
// CAPA: Presentation / Widgets (Hoja de Previsualización y Descarga)
// QUÉ HACE: Despliega la interfaz modal interactiva para previsualizar antes de exportar.
// CÓMO FUNCIONA: Observa `exportPreviewViewModelProvider` y adapta la altura.
// POR QUÉ: HIG ejecutiva sin colores saturados, adaptativo horizontal/vertical < 185 líneas.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../viewmodels/export_preview_viewmodel.dart';
import 'export_preview_widgets.dart';

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
    Future.microtask(() {
      if (mounted && ref.read(exportPreviewViewModelProvider) is! ExportPreviewLoaded) {
        _load();
      }
    });
  }

  Future<void> _load() => ref.read(exportPreviewViewModelProvider.notifier).loadPreview(
        fechaDesde: widget.fechaDesde,
        fechaHasta: widget.fechaHasta,
      );

  Future<void> _export({bool forceOfflineCsv = false}) async {
    final path = await ref.read(exportPreviewViewModelProvider.notifier).executeExport(
          fechaDesde: widget.fechaDesde,
          fechaHasta: widget.fechaHasta,
          forceOfflineCsv: forceOfflineCsv,
        );
    if (path != null && mounted) Navigator.of(context).pop(path);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exportPreviewViewModelProvider);
    final notifier = ref.read(exportPreviewViewModelProvider.notifier);

    return switch (state) {
      ExportPreviewIdle() ||
      ExportPreviewLoading() =>
        const SizedBox(height: 180, child: Center(child: CircularProgressIndicator.adaptive())),
      ExportPreviewError(:final message) => _buildError(message),
      ExportPreviewLoaded(:final data, :final format) => _buildLoaded(context, data, format, notifier),
      ExportPreviewExporting(:final format) => SizedBox(
          height: 180,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator.adaptive(),
                const SizedBox(height: 12),
                Text('Generando ${format.label}...', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ExportPreviewExported(:final filePath) => SizedBox(
          height: 160,
          child: Center(
            child: FilledButton(
              onPressed: () => Navigator.pop(context, filePath),
              child: const Text('Exportación lista · Cerrar'),
            ),
          ),
        ),
    };
  }

  Widget _buildLoaded(
    BuildContext context,
    ExportPreviewData data,
    ExportFormat format,
    ExportPreviewViewModel notifier,
  ) {
    final tieneDatos = data.totalRegistros > 0;
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, isLandscape ? 4 : 8, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExportSummaryRow(data: data),
          SizedBox(height: isLandscape ? 8 : 10),
          ExportFormatSelector(
            current: format,
            data: data,
            onSelect: (f) => notifier.setFormat(f, data),
          ),
          SizedBox(height: isLandscape ? 8 : 10),
          if (data.sample.isNotEmpty)
            SizedBox(
              height: isLandscape ? 135 : 190,
              child: ExportPreviewDataTable(sample: data.sample),
            )
          else
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No hay registros en el período seleccionado.')),
            ),
          SizedBox(height: isLandscape ? 8 : 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 12.5)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: tieneDatos ? () => _export() : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text(
                    tieneDatos ? 'Exportar ${format.label}' : 'Sin datos',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: context.cTextSecondary, size: 36),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
}
