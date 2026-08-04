// lib/core/services/excel_exporter.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../exceptions/app_exception.dart';
import '../exceptions/error_handler.dart';

/// Exportación de asistencias a Excel — único punto de implementación.
///
/// Consolida el flujo que antes se duplicaba en HomeScreen y
/// AdminDashboardScreen: GET /attendance/export/excel con token Bearer
/// (vía Dio), guardado en almacenamiento temporal y apertura con el visor
/// externo. En web la descarga no aplica (path_provider no existe).
final class ExcelExporter {
  const ExcelExporter(this._dio);

  final Dio _dio;

  /// Descarga el reporte (con filtros opcionales), lo guarda en almacenamiento
  /// local y trata de abrirlo. Retorna la ruta del archivo guardado.
  Future<String> exportAndOpen({Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<List<int>>(
        '/attendance/export/excel',
        queryParameters: (queryParameters == null || queryParameters.isEmpty)
            ? null
            : queryParameters,
        options: Options(
          responseType: ResponseType.bytes,
          // El reporte puede ser grande: timeout extendido SOLO para esta
          // descarga (el global de 15s abortaba la exportación).
          receiveTimeout: const Duration(minutes: 2),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw UnknownException(message: 'Respuesta vacía del servidor.');
      }

      Directory dir;
      try {
        dir = await getApplicationDocumentsDirectory();
      } catch (_) {
        dir = await getTemporaryDirectory();
      }

      final fileName =
          'asistencias_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      try {
        await launchUrl(
          Uri.file(file.path),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        // Si no hay visor externo o launchUrl no soporta file:// en esta plataforma,
        // el archivo ya quedó guardado en file.path
      }

      return file.path;
    } on AppException {
      rethrow;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    } catch (e) {
      throw UnknownException(
        message:
            'Error al exportar: ${e.toString().replaceFirst('Exception: ', '')}',
        originalError: e,
      );
    }
  }
}
