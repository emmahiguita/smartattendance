// ============================================================================
// ARCHIVO: consolidated_attendance_controller.dart
// CAPA: Presentation / Consolidated / Controllers
// QUÉ HACE: StateNotifier de Riverpod para consulta, creación manual, edición,
//           filtrado, ordenamiento y exportación del Consolidado de Asistencias.
// CÓMO FUNCIONA: Consulta `ConsolidatedAttendanceRepository`, filtra en memoria,
//                ejecuta registros/correcciones transaccionales y exporta.
// POR QUÉ: SRP de SOLID, Clean Architecture y 100% persistencia real (< 240 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../photo_attendance/data/photo_exporter.dart';
import '../../../../photo_attendance/data/photo_xlsx_exporter.dart';
import '../../../../photo_attendance/domain/local_actor.dart';
import '../../../../photo_attendance/domain/photo_record.dart';
import '../../../../photo_attendance/presentation/local_providers.dart';
import '../../../data/consolidated_attendance_repository.dart';
import '../../viewmodels/export_preview_state.dart';
import '../models/consolidated_record.dart';
import 'consolidated_attendance_state.dart';

class ConsolidatedAttendanceController
    extends StateNotifier<ConsolidatedAttendanceState> {
  ConsolidatedAttendanceController({
    required this.repository,
    required this.actor,
  }) : super(const ConsolidatedAttendanceState());

  final ConsolidatedAttendanceRepository repository;
  final LocalActor actor;

  /// QUÉ HACE: Carga inicial de jornadas desde SQLite y lista de sedes disponibles.
  Future<void> loadData({DateTime? start, DateTime? end}) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final days = await repository.fetchDays(from: start, to: end);
      final zones = await repository.fetchAvailableZones();
      if (!mounted) return;
      final records = days.map(ConsolidatedRecord.fromPhotoDay).toList();

      state = state.copyWith(
        isLoading: false,
        allRecords: records,
        availableZones: zones,
        startDate: start,
        endDate: end,
      );
      _applyFiltersAndSort();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al consultar asistencias: $e',
      );
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFiltersAndSort();
  }

  void setZone(String? zone) {
    state = state.copyWith(selectedZone: zone, clearZone: zone == null);
    _applyFiltersAndSort();
  }

  void setStatus(String? status) {
    state = state.copyWith(selectedStatus: status, clearStatus: status == null);
    _applyFiltersAndSort();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: start,
      clearStartDate: start == null,
      endDate: end,
      clearEndDate: end == null,
    );
    loadData(start: start, end: end);
  }

  void setSort(ConsolidatedSortColumn column) {
    if (state.sortColumn == column) {
      state = state.copyWith(sortAscending: !state.sortAscending);
    } else {
      state = state.copyWith(sortColumn: column, sortAscending: true);
    }
    _applyFiltersAndSort();
  }

  void toggleRowSelection(String journeyId) {
    final next = Set<String>.from(state.selectedIds);
    if (next.contains(journeyId)) {
      next.remove(journeyId);
    } else {
      next.add(journeyId);
    }
    state = state.copyWith(selectedIds: next);
  }

  void toggleSelectAll() {
    if (state.selectedIds.length == state.filteredRecords.length) {
      state = state.copyWith(selectedIds: const {});
    } else {
      state = state.copyWith(
        selectedIds: state.filteredRecords.map((r) => r.journeyId).toSet(),
      );
    }
  }

  void clearSelection() => state = state.copyWith(selectedIds: const {});

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearZone: true,
      clearStatus: true,
      clearStartDate: true,
      clearEndDate: true,
    );
    loadData();
  }

  Future<List<Map<String, dynamic>>> getWorkers() =>
      repository.fetchWorkersList();

  void _applyFiltersAndSort() {
    final query = state.searchQuery.trim().toLowerCase();
    final zone = state.selectedZone;
    final status = state.selectedStatus;

    final filtered = state.allRecords.where((r) {
      if (zone != null && r.zona != zone) return false;
      if (status != null && r.estado != status) return false;
      if (query.isNotEmpty) {
        final matchName = r.colaborador.toLowerCase().contains(query);
        final matchDoc = r.cedula.toLowerCase().contains(query);
        final matchZone = r.zona.toLowerCase().contains(query);
        if (!matchName && !matchDoc && !matchZone) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      int cmp;
      switch (state.sortColumn) {
        case ConsolidatedSortColumn.colaborador:
          cmp = a.colaborador.compareTo(b.colaborador);
          break;
        case ConsolidatedSortColumn.fecha:
          cmp = a.fecha.compareTo(b.fecha);
          break;
        case ConsolidatedSortColumn.entrada:
          cmp = a.entrada.compareTo(b.entrada);
          break;
        case ConsolidatedSortColumn.salida:
          cmp = a.salida.compareTo(b.salida);
          break;
        case ConsolidatedSortColumn.horas:
          cmp = a.horas.compareTo(b.horas);
          break;
        case ConsolidatedSortColumn.extras:
          cmp = a.extras.compareTo(b.extras);
          break;
        case ConsolidatedSortColumn.zona:
          cmp = a.zona.compareTo(b.zona);
          break;
      }
      return state.sortAscending ? cmp : -cmp;
    });

    state = state.copyWith(filteredRecords: filtered);
  }

  /// QUÉ HACE: Crea una nueva jornada de asistencia manual en SQLite.
  Future<bool> createManualRecord({
    required int workerId,
    required DateTime workDate,
    required TimeOfDay entradaTime,
    TimeOfDay? salidaTime,
    required String zoneName,
    required String status,
    required int? approvedSeconds,
    required String reason,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.createManualAttendance(
        workerId: workerId,
        workDate: workDate,
        entradaTime: entradaTime,
        salidaTime: salidaTime,
        zoneName: zoneName,
        status: status,
        approvedSeconds: approvedSeconds,
        reason: reason,
        adminDocument: actor.document,
      );
      await loadData(start: state.startDate, end: state.endDate);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al registrar asistencia: $e',
      );
      return false;
    }
  }

  /// QUÉ HACE: Aplica la corrección completa administrativa sobre una jornada.
  Future<bool> saveCorrection({
    required String journeyId,
    required String? newZone,
    required String newStatus,
    required int? newApprovedSeconds,
    required String reason,
    DateTime? newDate,
    TimeOfDay? newEntradaTime,
    TimeOfDay? newSalidaTime,
    int? newWorkerId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await repository.applyCorrection(
        journeyId: journeyId,
        newZone: newZone,
        newStatus: newStatus,
        newApprovedSeconds: newApprovedSeconds,
        reason: reason,
        adminDocument: actor.document,
        newDate: newDate,
        newEntradaTime: newEntradaTime,
        newSalidaTime: newSalidaTime,
        newWorkerId: newWorkerId,
      );
      if (!mounted) return true;
      await loadData(start: state.startDate, end: state.endDate);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al corregir: $e',
      );
      return false;
    }
  }

  /// QUÉ HACE: Exporta a Excel o CSV según el alcance especificado.
  Future<String?> export({
    required ExportFormat format,
    required ExportScope scope,
  }) async {
    state = state.copyWith(isExporting: true, clearError: true);
    try {
      List<PhotoDay> targetDays;
      switch (scope) {
        case ExportScope.all:
          targetDays = state.allRecords.map((r) => r.rawDay).toList();
          break;
        case ExportScope.filtered:
          targetDays = state.filteredRecords.map((r) => r.rawDay).toList();
          break;
        case ExportScope.selected:
          targetDays = state.allRecords
              .where((r) => state.selectedIds.contains(r.journeyId))
              .map((r) => r.rawDay)
              .toList();
          break;
      }
      if (targetDays.isEmpty) {
        throw StateError('No hay registros seleccionados para exportar.');
      }

      final path = format == ExportFormat.xlsx
          ? await PhotoXlsxExporter().exportSpecificDays(targetDays)
          : await PhotoExporter.exportSpecificDays(targetDays);

      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: 'Consolidado de Asistencias SmartAttendance',
          ),
        );
      } catch (_) {
        try {
          await launchUrl(Uri.file(path), mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
      state = state.copyWith(isExporting: false);
      return path;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'Fallo al exportar: $e',
      );
      return null;
    }
  }
}

final consolidatedRepositoryProvider =
    Provider<ConsolidatedAttendanceRepository>((ref) {
  return ConsolidatedAttendanceRepository(
    database: ref.watch(localPhotoDatabaseProvider),
    actor: ref.watch(localActorProvider),
  );
});

final consolidatedAttendanceControllerProvider = StateNotifierProvider<
    ConsolidatedAttendanceController, ConsolidatedAttendanceState>((ref) {
  return ConsolidatedAttendanceController(
    repository: ref.watch(consolidatedRepositoryProvider),
    actor: ref.watch(localActorProvider),
  );
});
