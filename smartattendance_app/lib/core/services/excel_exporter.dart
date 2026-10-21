// lib/core/services/excel_exporter.dart
import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../exceptions/app_exception.dart';
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
  /// Descarga del backend o genera CSV local. Abre el archivo resultante.
  ///
  /// [queryParameters] soporta 'formato' ('xlsx'|'csv'), 'fecha_desde', 'fecha_hasta'.
  /// Si 'formato' está presente y es 'csv', se descarga CSV del backend.
  Future<String> exportAndOpen({Map<String, dynamic>? queryParameters}) async {
    // Try remote first
    try {
      final params = (queryParameters == null || queryParameters.isEmpty)
          ? null
          : queryParameters;
      final isCsv = params != null && params['formato'] == 'csv';
      final ext = isCsv ? 'csv' : 'xlsx';

      final response = await _dio.get<List<int>>(
        '/attendance/export/excel',
        queryParameters: params,
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
          'asistencias_${DateTime.now().millisecondsSinceEpoch}.$ext';
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
      // Offline: generate CSV from local data.
      // Siempre CSV — el fallback local no puede generar .xlsx real.
      AppLogger.info('Offline mode: generating CSV report from local data');
      final path = await _generateLocalCsv(
        fechaDesde: queryParameters?['fecha_desde'] as String?,
        fechaHasta: queryParameters?['fecha_hasta'] as String?,
      );
      return path;
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

  /// Genera un CSV agrupado por empleado + fecha, con cálculo de horas y
  /// columnas idénticas al Excel del backend. Soporta filtros por fecha.
  Future<String> _generateLocalCsv({
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    if (_localDb == null) {
      throw UnknownException(message: 'No hay datos locales para exportar.');
    }

    final rawRows = await _localDb.getAllAttendanceHistory();
    if (rawRows.isEmpty) {
      throw UnknownException(message: 'No hay registros de asistencia locales.');
    }

    // ── Filtrar por rango de fechas si se especificó ──
    DateTime? desde = fechaDesde != null ? DateTime.tryParse(fechaDesde) : null;
    DateTime? hasta = fechaHasta != null ? DateTime.tryParse(fechaHasta) : null;

    final filtered = rawRows.where((row) {
      final raw = row['fecha'] as String?;
      if (raw == null) return false;
      final d = DateTime.tryParse(raw);
      if (d == null) return false;
      if (desde != null && d.isBefore(desde)) return false;
      if (hasta != null && d.isAfter(hasta.add(const Duration(days: 1)))) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      final rango = desde != null || hasta != null ? ' en el rango seleccionado' : '';
      throw UnknownException(message: 'No hay registros$rango para exportar.');
    }

    // ── Agrupar por (usuario_id, fecha) — mismo algoritmo del backend ──
    final Map<(int, String), List<Map<String, dynamic>>> grouped = {};
    for (final r in filtered) {
      final uid = r['usuario_id'] as int;
      final fecha = r['fecha'] as String;
      grouped.putIfAbsent((uid, fecha), () => []).add(r);
    }

    // Ordenar cada grupo por hora
    for (final recs in grouped.values) {
      recs.sort((a, b) => (a['hora'] as String).compareTo(b['hora'] as String));
    }

    // ── Escribir CSV ──
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = await getTemporaryDirectory();
    }

    final fileName = 'asistencias_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    final sink = file.openWrite(encoding: utf8);
    sink.write('\uFEFF'); // BOM for Excel UTF-8 detection

    sink.writeln(
      'Nombre,Cédula,Cargo,Fecha,Entrada,Salida Almuerzo,Regreso Almuerzo,Salida Final,Horas Laboradas,Estado',
    );

    // Ordenar por fecha asc, luego por nombre
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final cmp = a.$2.compareTo(b.$2);
        return cmp != 0 ? cmp : a.$1.compareTo(b.$1);
      });

    for (final (uid, fecha) in sortedKeys) {
      final recs = grouped[(uid, fecha)]!;
      final nombre = '${recs.first['nombre'] ?? ''} ${recs.first['apellido'] ?? ''}'.trim();
      final cedula = recs.first['cedula'] as String? ?? '';
      final cargo = _escapeCsv(recs.first['cargo'] as String? ?? '');
      final fechaFormatted = _formatDateForDisplay(fecha);

      // Mapear por tipo
      final timesByType = <String, String>{};
      for (final r in recs) {
        timesByType[r['tipo'] as String] = _truncateHora(r['hora'] as String);
      }

      final entrada = timesByType['entrada'] ?? '-';
      final salidaAlmuerzo = timesByType['salida_almuerzo'] ?? '-';
      final regresoAlmuerzo = timesByType['regreso_almuerzo'] ?? '-';
      final salida = timesByType['salida'] ?? '-';

      // Calcular horas laboradas
      int totalMinutes = 0;
      if (timesByType.containsKey('entrada') && timesByType.containsKey('salida_almuerzo')) {
        totalMinutes += _timeDiffMinutes(timesByType['entrada']!, timesByType['salida_almuerzo']!);
      } else if (timesByType.containsKey('entrada') && timesByType.containsKey('salida') &&
                 !timesByType.containsKey('salida_almuerzo')) {
        totalMinutes += _timeDiffMinutes(timesByType['entrada']!, timesByType['salida']!);
      }
      if (timesByType.containsKey('regreso_almuerzo') && timesByType.containsKey('salida')) {
        totalMinutes += _timeDiffMinutes(timesByType['regreso_almuerzo']!, timesByType['salida']!);
      }

      final horas = totalMinutes > 0
          ? '${totalMinutes ~/ 60}h ${(totalMinutes % 60).toString().padLeft(2, '0')}m'
          : '-';

      final estado = timesByType.containsKey('salida')
          ? 'Finalizado'
          : (timesByType.containsKey('entrada') ? 'Trabajando' : 'Ausente');

      sink.writeln(
        '${_escapeCsv(nombre)},${_escapeCsv(cedula)},$cargo,$fechaFormatted,'
        '$entrada,$salidaAlmuerzo,$regresoAlmuerzo,$salida,$horas,$estado',
      );
    }

    await sink.flush();
    await sink.close();

    try {
      await launchUrl(Uri.file(file.path), mode: LaunchMode.externalApplication);
    } catch (_) {}

    return file.path;
  }

  /// Convierte "15:30:45" → "15:30"
  static String _truncateHora(String h) {
    final parts = h.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : h;
  }

  /// Convierte "2026-08-07" → "07/08/2026"
  static String _formatDateForDisplay(String raw) {
    final parts = raw.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return raw;
  }

  /// Diferencia en minutos entre dos strings "HH:MM" o "HH:MM:SS"
  static int _timeDiffMinutes(String from, String to) {
    int parse(String t) {
      final parts = t.split(':');
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }
    final diff = parse(to) - parse(from);
    return diff > 0 ? diff : 0;
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
