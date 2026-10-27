// lib/features/attendance/presentation/viewmodels/export_preview_state.dart
// ============================================================================
// ARCHIVO: export_preview_state.dart
// CAPA: Presentation (Modelos y Estados de Vista para Previsualización)
// ----------------------------------------------------------------------------
// QUÉ HACE:
// Define la estructura inmutable de los datos previsualizados antes de exportar
// (conteos, métricas y filas de ejemplo) y la máquina de estados sellada
// (Sealed Class) para el flujo de exportación (Idle, Loading, Loaded, etc.).
//
// CÓMO FUNCIONA:
// - [ExportFormat]: Enum que define los formatos soportados (.xlsx y .csv).
// - [ExportPreviewData]: Contenedor con totales de jornadas, personas y registros.
// - [ExportPreviewState]: Jerarquía sellada evaluada exhaustivamente mediante
//   expresiones pattern matching (`switch (state) { ... }`).
//
// POR QUÉ:
// Aplica el Principio de Responsabilidad Única (SRP) de SOLID:
// Desacopla los contratos de estado del controlador ViewModel, garantizando
// archivos concisos (< 200 líneas), testeables y fáciles de comprender.
// ============================================================================

/// Formatos de exportación disponibles para reportes de asistencia.
enum ExportFormat {
  xlsx('XLSX'),
  csv('CSV');

  const ExportFormat(this.label);
  final String label;
}

/// DTO inmutable con la información previa de la tabla antes de exportar.
class ExportPreviewData {
  const ExportPreviewData({
    required this.totalRegistros,
    required this.empleadosUnicos,
    required this.entradas,
    required this.salidas,
    this.totalJornadas = 0,
    this.horasExtrasTotal = '0h 00m',
    required this.tamanoEstimadoXlsx,
    required this.tamanoEstimadoCsv,
    required this.sample,
  });

  /// Total general de marcas registradas en el período.
  final int totalRegistros;

  /// Cantidad de trabajadores únicos con asistencia en el rango.
  final int empleadosUnicos;

  /// Conteo de marcas tipo entrada.
  final int entradas;

  /// Conteo de marcas tipo salida final.
  final int salidas;

  /// Total de jornadas completas procesadas.
  final int totalJornadas;

  /// Total de horas extras acumuladas en el período.
  final String horasExtrasTotal;

  /// Estimado en bytes del archivo Excel resultante.
  final int tamanoEstimadoXlsx;

  /// Estimado en bytes del archivo CSV resultante.
  final int tamanoEstimadoCsv;

  /// Filas reales para previsualización inmediata en la tabla.
  final List<Map<String, dynamic>> sample;
}

/// Estados posibles de la vista de previsualización y exportación.
sealed class ExportPreviewState {
  const ExportPreviewState();
}

/// Estado inicial sin datos cargados.
final class ExportPreviewIdle extends ExportPreviewState {
  const ExportPreviewIdle();
}

/// Estado de carga mientras se consultan las marcas locales/remotas.
final class ExportPreviewLoading extends ExportPreviewState {
  const ExportPreviewLoading();
}

/// Estado con datos listos para visualizar en la tabla modal.
final class ExportPreviewLoaded extends ExportPreviewState {
  const ExportPreviewLoaded(this.data, this.format);
  final ExportPreviewData data;
  final ExportFormat format;
}

/// Estado mientras se genera el libro XLSX o el archivo CSV.
final class ExportPreviewExporting extends ExportPreviewState {
  const ExportPreviewExporting(this.format);
  final ExportFormat format;
}

/// Estado cuando el archivo fue generado y abierto en el dispositivo.
final class ExportPreviewExported extends ExportPreviewState {
  const ExportPreviewExported(this.filePath);
  final String filePath;
}

/// Estado ante cualquier fallo de lectura o exportación.
final class ExportPreviewError extends ExportPreviewState {
  const ExportPreviewError(this.message);
  final String message;
}
