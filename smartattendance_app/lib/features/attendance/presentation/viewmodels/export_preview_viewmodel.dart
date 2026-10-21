// lib/features/attendance/presentation/viewmodels/export_preview_viewmodel.dart
// ===================================================================
// ViewModel para el preview de exportación de asistencias.
// Carga metadata + sample rows desde /attendance/export/preview,
// permite elegir formato, y dispara la exportación vía ExcelExporter.
// ===================================================================
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/services/excel_exporter.dart';
import '../../../../core/localstore/local_database_service.dart';

enum ExportFormat { xlsx, csv }

class ExportPreviewData {
  const ExportPreviewData({
    required this.totalRegistros,
    required this.empleadosUnicos,
    required this.entradas,
    required this.salidas,
    required this.tamanoEstimadoXlsx,
    required this.tamanoEstimadoCsv,
    required this.sample,
  });

  final int totalRegistros;
  final int empleadosUnicos;
  final int entradas;
  final int salidas;
  final int tamanoEstimadoXlsx;
  final int tamanoEstimadoCsv;
  final List<Map<String, dynamic>> sample;
}

sealed class ExportPreviewState {
  const ExportPreviewState();
}

final class ExportPreviewIdle extends ExportPreviewState {
  const ExportPreviewIdle();
}

final class ExportPreviewLoading extends ExportPreviewState {
  const ExportPreviewLoading();
}

final class ExportPreviewLoaded extends ExportPreviewState {
  const ExportPreviewLoaded(this.data, this.format);
  final ExportPreviewData data;
  final ExportFormat format;
}

final class ExportPreviewExporting extends ExportPreviewState {
  const ExportPreviewExporting(this.format);
  final ExportFormat format;
}

final class ExportPreviewExported extends ExportPreviewState {
  const ExportPreviewExported(this.filePath);
  final String filePath;
}

final class ExportPreviewError extends ExportPreviewState {
  const ExportPreviewError(this.message);
  final String message;
}

class ExportPreviewViewModel extends StateNotifier<ExportPreviewState> {
  ExportPreviewViewModel(this._dio, this._localDb)
      : super(const ExportPreviewIdle());

  final Dio _dio;
  final LocalDatabaseService _localDb;
  ExportFormat _format = ExportFormat.xlsx;

  ExportFormat get format => _format;

  void setFormat(ExportFormat f, ExportPreviewData data) {
    _format = f;
    state = ExportPreviewLoaded(data, f);
  }

  Future<void> loadPreview({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) async {
    state = const ExportPreviewLoading();
    try {
      final queryParams = <String, String>{};
      if (fechaDesde != null) {
        queryParams['fecha_desde'] = fechaDesde.toIso8601String().split('T').first;
      }
      if (fechaHasta != null) {
        queryParams['fecha_hasta'] = fechaHasta.toIso8601String().split('T').first;
      }

      final response = await _dio.get(
        '/attendance/export/preview',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final data = ExportPreviewData(
        totalRegistros: response.data['total_registros'] as int? ?? 0,
        empleadosUnicos: response.data['empleados_unicos'] as int? ?? 0,
        entradas: response.data['entradas'] as int? ?? 0,
        salidas: response.data['salidas'] as int? ?? 0,
        tamanoEstimadoXlsx: response.data['tamano_estimado_xlsx'] as int? ?? 0,
        tamanoEstimadoCsv: response.data['tamano_estimado_csv'] as int? ?? 0,
        sample: (response.data['sample'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
      );
      state = ExportPreviewLoaded(data, _format);
    } on DioException catch (e) {
      if (_isNetworkError(e)) {
        state = const ExportPreviewError('Sin conexión. El preview requiere internet.');
      } else {
        state = ExportPreviewError('Error del servidor: ${e.response?.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Preview load failed', error: e);
      state = const ExportPreviewError('Error inesperado al cargar el preview.');
    }
  }

  Future<String?> executeExport({
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    bool forceOfflineCsv = false,
  }) async {
    state = ExportPreviewExporting(_format);
    try {
      final queryParams = <String, String>{};
      if (fechaDesde != null) {
        queryParams['fecha_desde'] = fechaDesde.toIso8601String().split('T').first;
      }
      if (fechaHasta != null) {
        queryParams['fecha_hasta'] = fechaHasta.toIso8601String().split('T').first;
      }
      // Si es offline forzado, no ponemos formato — ExcelExporter hará fallback a CSV local
      if (!forceOfflineCsv) {
        queryParams['formato'] = _format.name;
      }

      final path = await ExcelExporter(_dio, localDb: _localDb).exportAndOpen(
        queryParameters: queryParams,
      );

      state = ExportPreviewExported(path);
      return path;
    } catch (e) {
      state = ExportPreviewError('Error al exportar: $e');
      return null;
    }
  }

  void reset() => state = const ExportPreviewIdle();

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.type == DioExceptionType.unknown &&
            e.error != null &&
            e.error.toString().contains('SocketException'));
  }

  /// Formatea bytes a cadena legible (KB / MB).
  static String formatSize(int bytes) {
    if (bytes > 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}

final exportPreviewViewModelProvider =
    StateNotifierProvider<ExportPreviewViewModel, ExportPreviewState>((ref) {
  return ExportPreviewViewModel(
    ref.watch(dioProvider),
    ref.watch(localDatabaseServiceProvider),
  );
});
