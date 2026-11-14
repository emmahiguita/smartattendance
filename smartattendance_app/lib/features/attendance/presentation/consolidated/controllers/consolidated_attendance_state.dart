// ============================================================================
// ARCHIVO: consolidated_attendance_state.dart
// CAPA: Presentation / Consolidated / Controllers
// QUÉ HACE: Estado inmutable de la pantalla de gestión del Consolidado de Asistencias.
// CÓMO FUNCIONA: Mantiene listas de registros, filtros activos, selecciones y métricas.
// POR QUÉ: Desacopla estado del controlador cumpliendo SRP y arquitectura limpia.
// ============================================================================

import '../models/consolidated_record.dart';

enum ConsolidatedSortColumn {
  colaborador,
  fecha,
  entrada,
  salida,
  horas,
  extras,
  zona,
}

enum ExportScope {
  all('Todos los registros'),
  filtered('Registros filtrados'),
  selected('Selección actual');

  const ExportScope(this.label);
  final String label;
}

class ConsolidatedAttendanceState {
  const ConsolidatedAttendanceState({
    this.isLoading = false,
    this.isExporting = false,
    this.errorMessage,
    this.allRecords = const [],
    this.filteredRecords = const [],
    this.selectedIds = const {},
    this.searchQuery = '',
    this.selectedZone,
    this.selectedStatus,
    this.startDate,
    this.endDate,
    this.sortColumn = ConsolidatedSortColumn.fecha,
    this.sortAscending = false,
    this.availableZones = const [],
  });

  final bool isLoading;
  final bool isExporting;
  final String? errorMessage;
  final List<ConsolidatedRecord> allRecords;
  final List<ConsolidatedRecord> filteredRecords;
  final Set<String> selectedIds;
  final String searchQuery;
  final String? selectedZone;
  final String? selectedStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final ConsolidatedSortColumn sortColumn;
  final bool sortAscending;
  final List<String> availableZones;

  int get totalJornadas => filteredRecords.length;

  int get personalUnico {
    final docs = filteredRecords.map((r) => r.cedula).toSet();
    return docs.length;
  }

  int get totalEntradas {
    return filteredRecords.where((r) => r.entrada != '-').length;
  }

  String get totalExtrasFormatted {
    var totalMinutes = 0;
    for (final r in filteredRecords) {
      final text = r.extras;
      final match = RegExp(r'(\d+)h\s*(\d+)m').firstMatch(text);
      if (match != null) {
        final h = int.tryParse(match.group(1) ?? '0') ?? 0;
        final m = int.tryParse(match.group(2) ?? '0') ?? 0;
        totalMinutes += (h * 60) + m;
      }
    }
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  int get selectedCount => selectedIds.length;

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedZone != null ||
      selectedStatus != null ||
      startDate != null ||
      endDate != null;

  ConsolidatedAttendanceState copyWith({
    bool? isLoading,
    bool? isExporting,
    String? errorMessage,
    bool clearError = false,
    List<ConsolidatedRecord>? allRecords,
    List<ConsolidatedRecord>? filteredRecords,
    Set<String>? selectedIds,
    String? searchQuery,
    String? selectedZone,
    bool clearZone = false,
    String? selectedStatus,
    bool clearStatus = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    ConsolidatedSortColumn? sortColumn,
    bool? sortAscending,
    List<String>? availableZones,
  }) {
    return ConsolidatedAttendanceState(
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      allRecords: allRecords ?? this.allRecords,
      filteredRecords: filteredRecords ?? this.filteredRecords,
      selectedIds: selectedIds ?? this.selectedIds,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedZone: clearZone ? null : (selectedZone ?? this.selectedZone),
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      sortColumn: sortColumn ?? this.sortColumn,
      sortAscending: sortAscending ?? this.sortAscending,
      availableZones: availableZones ?? this.availableZones,
    );
  }
}
