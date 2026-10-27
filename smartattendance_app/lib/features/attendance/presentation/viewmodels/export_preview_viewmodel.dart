// lib/features/attendance/presentation/viewmodels/export_preview_viewmodel.dart
// ============================================================================
// ARCHIVO: export_preview_viewmodel.dart
// CAPA: Presentation / State Management (Riverpod StateNotifier)
// QUÉ HACE: Orquesta lectura SQLite, previsualización tabular y exportación.
// CÓMO FUNCIONA: Offline-First con `PhotoXlsxExporter` y `SharePlus` nativo.
// POR QUÉ: SRP de SOLID, libre de timeouts y estrictamente menor a 200 líneas.
// ============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localstore/local_database_service.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/services/excel_exporter.dart';
import '../../../photo_attendance/data/photo_xlsx_exporter.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import 'export_preview_state.dart';

export 'export_preview_state.dart';

class ExportPreviewViewModel extends StateNotifier<ExportPreviewState> {
  ExportPreviewViewModel(this._dio, {LocalDatabaseService? localDb, LocalAttendanceRepository? photoRepo})
      : _localDb = localDb,
        _photoRepo = photoRepo,
        super(const ExportPreviewIdle()) {
    // Carga anticipada instantánea al inicializar el ViewModel
    loadPreview();
  }

  final Dio _dio;
  final LocalDatabaseService? _localDb;
  final LocalAttendanceRepository? _photoRepo;
  ExportFormat _format = ExportFormat.xlsx;

  ExportFormat get format => _format;

  /// Cambia el formato seleccionado conservando la previsualización intacta.
  void setFormat(ExportFormat f, ExportPreviewData data) {
    _format = f;
    state = ExportPreviewLoaded(data, f);
  }

  /// Carga de datos con patrón Offline-First para visualización inmediata.
  Future<void> loadPreview({DateTime? fechaDesde, DateTime? fechaHasta}) async {
    state = const ExportPreviewLoading();
    await _loadFromLocal(fechaDesde: fechaDesde, fechaHasta: fechaHasta);
  }

  /// Consulta SQLite local (`photo_marks` y `journeys`) y construye la tabla previa.
  Future<void> _loadFromLocal({DateTime? fechaDesde, DateTime? fechaHasta}) async {
    try {
      final desdeOnly = fechaDesde != null ? DateTime(fechaDesde.year, fechaDesde.month, fechaDesde.day) : null;
      final hastaOnly = fechaHasta != null ? DateTime(fechaHasta.year, fechaHasta.month, fechaHasta.day, 23, 59, 59) : null;

      if (_photoRepo != null) {
        final days = await _photoRepo.days(limit: 100);
        final filtered = days.where((d) {
          if (desdeOnly != null && d.date.isBefore(desdeOnly)) return false;
          if (hastaOnly != null && d.date.isAfter(hastaOnly)) return false;
          return true;
        }).toList();

        final sample = <Map<String, dynamic>>[];
        var entradas = 0, salidas = 0, totalMarks = 0, totalExtrasMinutes = 0;
        final docs = <String>{};

        for (final day in filtered) {
          totalMarks += day.records.length;
          docs.add(day.worker.document);

          final e = day.marks('entrada').firstOrNull;
          final s = day.marks('salida').firstOrNull;
          if (e != null) entradas++;
          if (s != null) salidas++;

          final dur = day.totals.active;
          final horasStr = dur > Duration.zero ? '${dur.inHours}h ${(dur.inMinutes % 60).toString().padLeft(2, '0')}m' : '-';

          // Cálculo real de horas extras según jornada legal (8h) o tiempo aprobado
          final approved = day.approvedSeconds;
          var extras = Duration.zero;
          if (approved != null && approved > 0) {
            extras = Duration(seconds: approved);
          } else if (day.totals.additional != null && day.totals.additional! > Duration.zero) {
            extras = day.totals.additional!;
          } else if (day.totals.active > const Duration(hours: 8)) {
            extras = day.totals.active - const Duration(hours: 8);
          }
          final extrasStr = extras > Duration.zero
              ? '${extras.inHours}h ${(extras.inMinutes % 60).toString().padLeft(2, '0')}m'
              : '0h 00m';
          totalExtrasMinutes += extras.inMinutes;

          sample.add({
            'nombre': day.worker.name,
            'cedula': day.worker.document,
            'cargo': day.worker.job,
            'zona': day.zoneName ?? 'Sede Principal Operativa',
            'fecha': '${day.date.day.toString().padLeft(2, '0')}/${day.date.month.toString().padLeft(2, '0')}/${day.date.year}',
            'entrada': e != null ? ColombiaClock.hour(e.capturedAt) : '-',
            'salida': s != null ? ColombiaClock.hour(s.capturedAt) : '-',
            'horas': horasStr,
            'extras': extrasStr,
            'estado': day.status == 'closed' ? 'Cerrada' : 'Abierta',
          });
        }

        final data = ExportPreviewData(
          totalRegistros: totalMarks,
          totalJornadas: filtered.length,
          empleadosUnicos: docs.length,
          entradas: entradas,
          salidas: salidas,
          horasExtrasTotal: '${totalExtrasMinutes ~/ 60}h ${(totalExtrasMinutes % 60).toString().padLeft(2, '0')}m',
          tamanoEstimadoXlsx: totalMarks * 180 + 4096,
          tamanoEstimadoCsv: totalMarks * 120 + 256,
          sample: sample,
        );
        state = ExportPreviewLoaded(data, _format);
        return;
      }
      state = ExportPreviewLoaded(const ExportPreviewData(totalRegistros: 0, empleadosUnicos: 0, entradas: 0, salidas: 0, tamanoEstimadoXlsx: 0, tamanoEstimadoCsv: 0, sample: []), _format);
    } catch (e) {
      AppLogger.error('Error cargando preview local', error: e);
      state = ExportPreviewError('Error al leer asistencias locales: $e');
    }
  }

  /// Ejecuta la exportación real a Excel (.xlsx) o CSV (.csv) y abre el archivo.
  Future<String?> executeExport({DateTime? fechaDesde, DateTime? fechaHasta, bool forceOfflineCsv = false}) async {
    state = ExportPreviewExporting(_format);
    try {
      String path;
      if (_photoRepo != null) {
        if (_format == ExportFormat.xlsx) {
          final list = await PhotoXlsxExporter().export(_photoRepo);
          path = list.first;
        } else {
          path = await _photoRepo.exportCsv();
        }
      } else {
        path = await ExcelExporter(_dio, localDb: _localDb).exportAndOpen(queryParameters: {'formato': _format.name});
      }

      // Abre el selector nativo de Android (Google Sheets, Excel, Drive, WhatsApp)
      try {
        await SharePlus.instance.share(ShareParams(files: [XFile(path)], text: 'Consolidado de Asistencia SmartAttendance'));
      } catch (_) {
        try {
          await launchUrl(Uri.file(path), mode: LaunchMode.externalApplication);
        } catch (_) {}
      }

      state = ExportPreviewExported(path);
      return path;
    } catch (e) {
      state = ExportPreviewError('Error al exportar: $e');
      return null;
    }
  }

  /// Limpia el estado del ViewModel al cerrar el modal.
  void reset() => state = const ExportPreviewIdle();

  /// Formatea bytes a cadena legible (ej. 14 KB o 2.1 MB).
  static String formatSize(int bytes) {
    if (bytes > 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}

/// Proveedor Riverpod para el ciclo de vida de la pantalla de exportación.
final exportPreviewViewModelProvider = StateNotifierProvider<ExportPreviewViewModel, ExportPreviewState>((ref) {
  return ExportPreviewViewModel(
    ref.watch(dioProvider),
    localDb: ref.watch(localDatabaseServiceProvider),
    photoRepo: ref.watch(localPhotoRepositoryProvider),
  );
});
