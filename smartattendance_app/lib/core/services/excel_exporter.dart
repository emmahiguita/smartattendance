// lib/core/services/excel_exporter.dart
import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../exceptions/app_exception.dart';
import '../exceptions/error_handler.dart';
import '../localstore/local_database_service.dart';
import '../logging/app_logger.dart';

/// Exportación de asistencias a Excel — exporta local o remoto.
///
/// Si hay backend disponible, descarga del servidor. Si no, genera un
/// archivo CSV local con los datos de SQLite que Excel puede abrir.
final class ExcelExporter {
  const ExcelExporter(this._dio, {LocalDatabaseService? localDb})
      : _localDb = localDb;

  final Dio _dio;
  final LocalDatabaseService? _localDb;

  /// Descarga el reporte (con filtros opcionales), lo guarda en almacenamiento
  /// local y trata de abrirlo. Retorna la ruta del archivo guardado.
  Future<String> exportAndOpen({Map<String, dynamic>? queryParameters}) async {
    // Try remote first
    try {
      final response = await _dio.get<List<int>>(
        '/attendance/export/excel',
        queryParameters: (queryParameters == null || queryParameters.isEmpty)
            ? null
            : queryParameters,
        options: Options(
          responseType: ResponseType.bytes,
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
      } catch (_) {}

      return file.path;
    } on DioException catch (_) {
      // Offline: generate CSV from local data
      AppLogger.info('Offline mode: generating Excel report from local data');
      return _generateLocalCsv();
    } on AppException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        message:
            'Error al exportar: ${e.toString().replaceFirst('Exception: ', '')}',
        originalError: e,
      );
    }
  }

  /// Genera un archivo CSV con los datos de asistencia locales.
  Future<String> _generateLocalCsv() async {
    if (_localDb == null) {
      throw UnknownException(
          message: 'No hay datos locales para exportar.');
    }

    final rows = await _localDb!.getAllAttendanceHistory();

    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = await getTemporaryDirectory();
    }

    final fileName =
        'asistencias_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');

    // BOM for Excel UTF-8 detection
    final sink = file.openWrite(encoding: utf8);
    sink.write('\uFEFF');

    // Header
    sink.writeln(
        'ID,Empleado,Cédula,Cargo,Tipo,Fecha,Hora,Latitud,Longitud,Dirección');

    for (final row in rows) {
      final nombre = '${row['nombre'] ?? ''} ${row['apellido'] ?? ''}'.trim();
      final tipo = row['tipo'] ?? '';
      final fecha = row['fecha'] ?? '';
      final hora = row['hora'] ?? '';
      final lat = row['latitud']?.toString() ?? '';
      final lng = row['longitud']?.toString() ?? '';
      final dir2 = _escapeCsv(row['direccion'] ?? '');
      final cargo = _escapeCsv(row['cargo'] ?? '');
      final cedula = row['cedula'] ?? '';

      sink.writeln(
          '${row['id']},$nombre,$cedula,$cargo,$tipo,$fecha,$hora,$lat,$lng,$dir2');
    }

    await sink.flush();
    await sink.close();

    try {
      await launchUrl(
        Uri.file(file.path),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}

    return file.path;
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
