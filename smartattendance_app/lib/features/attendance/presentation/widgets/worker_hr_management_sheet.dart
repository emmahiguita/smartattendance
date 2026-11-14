// ============================================================================
// ARCHIVO: worker_hr_management_sheet.dart
// QUÉ HACE: Hoja modal estilo Apple iOS Inset Grouped para gestionar a un
//           colaborador individual: Equipo/Cuadrilla, Zona GPS, Horario
//           pactado (`WorkSchedule`), liquidación de Horas Extras y marcación.
// CÓMO FUNCIONA: Muestra los datos de `LocalWorker`, permite abrir la ventana
//                flotante `WorkerAssignmentDialog` y audita la última jornada.
// POR QUÉ: Sustituye cajas Material por secciones iOS limpias (< 190 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import 'worker_password_dialog.dart';
import 'worker_management_details.dart';


import '../../../photo_attendance/domain/photo_record.dart';

import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/photo_capture_screen.dart';
import '../../../photo_attendance/presentation/worker_assignment_dialog.dart';



/// Hoja ejecutiva para administrar turno, cuadrilla y horas extras de un trabajador.
class WorkerHrManagementSheet extends ConsumerStatefulWidget {
  const WorkerHrManagementSheet({super.key, required this.worker});
  final LocalWorker worker;

  static Future<void> show(BuildContext context, {required LocalWorker worker}) =>
      showIosFloatingGlassSheet(context: context, title: 'Gestión Laboral y Turno', subtitle: worker.name, child: WorkerHrManagementSheet(worker: worker));

  @override
  ConsumerState<WorkerHrManagementSheet> createState() => _WorkerHrManagementSheetState();
}

class _WorkerHrManagementSheetState extends ConsumerState<WorkerHrManagementSheet> {
  late LocalWorker _worker = widget.worker;
  PhotoDay? _latestDay;
  bool _loadingDay = true, _reviewing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadLatestDay();
  }

  /// QUÉ HACE: Consulta la última jornada registrada del colaborador en SQLite.
  Future<void> _loadLatestDay() async {
    setState(() => _loadingDay = true);
    try {
      final days = await ref.read(localPhotoRepositoryProvider).days(search: _worker.document, limit: 1);
      if (mounted) setState(() => (_latestDay = days.isNotEmpty ? days.first : null, _loadingDay = false));
    } catch (_) {
      if (mounted) setState(() => _loadingDay = false);
    }
  }

  /// QUÉ HACE: Abre el diálogo de asignación de turno/cuadrilla y refresca el estado.
  Future<void> _openAssignmentDialog() async {
    final updated = await showDialog<bool>(context: context, builder: (_) => WorkerAssignmentDialog(worker: _worker));
    if (updated == true && mounted) {
      ref.invalidate(localWorkersProvider);
      ref.invalidate(allOvertimeDaysProvider);
      final list = await ref.read(localPhotoRepositoryProvider).workers();
      final fresh = list.firstWhere((w) => w.id == _worker.id, orElse: () => _worker);
      if (mounted) { setState(() => _worker = fresh); _loadLatestDay(); }
    }
  }

  /// QUÉ HACE: Aprueba o rechaza las horas extras de la última jornada.
  Future<void> _reviewOvertime(bool approve) async {
    final day = _latestDay;
    if (day == null || _reviewing) return;
    setState(() => _reviewing = true);
    try {
      await ref.read(localAdminStoreProvider).review(day, approve: approve, abandon: false);
      ref.invalidate(allOvertimeDaysProvider);
      if (mounted) { setState(() => _message = approve ? 'Horas extras aprobadas por el Administrador' : 'Tiempo adicional rechazado'); await _loadLatestDay(); }
    } catch (e) {
      if (mounted) setState(() => _message = e is FormatException ? e.message : 'Error al registrar revisión');
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  /// QUÉ HACE: Aplica el horario asignado a una jornada abierta sin horario previo.
  Future<void> _applyScheduleToDay() async {
    final day = _latestDay;
    if (day == null || _reviewing) return;
    setState(() => _reviewing = true);
    try {
      await ref.read(localAdminStoreProvider).applySchedule(day);
      ref.invalidate(allOvertimeDaysProvider);
      if (mounted) { setState(() => _message = 'Jornada pactada vinculada al registro'); await _loadLatestDay(); }
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  /// QUÉ HACE: Desvincula al colaborador de la tabla `workers` tras confirmación.
  Future<void> _deleteWorker() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Dar de Baja Colaborador'),
        content: Text('¿Deseas desvincular a "${_worker.name}" de la nómina y registros locales?'),
        actions: [CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')), CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(ctx, true), child: const Text('Desvincular'))],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await ref.read(localAdminStoreProvider).deleteWorker(_worker.id);
        ref.invalidate(localWorkersProvider);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) setState(() => _message = e is FormatException ? e.message : 'Error al desvincular.');
      }
    }
  }

  Future<void> _setPassword() async {
    final saved = await WorkerPasswordDialog.show(context, _worker);
    if (saved == true && mounted) {
      setState(() => _message = 'Contraseña local establecida correctamente.');
    }
  }

  @override
  Widget build(BuildContext context) => WorkerManagementDetails(
    worker: _worker, latestDay: _latestDay, loadingDay: _loadingDay,
    reviewing: _reviewing, message: _message,
    canDelete: ref.watch(localActorProvider).isStrictAdmin,
    onAssignment: _openAssignmentDialog, onPassword: _setPassword,
    onApplySchedule: _applyScheduleToDay, onReviewOvertime: _reviewOvertime,
    onDelete: _deleteWorker,
    onCapture: () {
      Navigator.pop(context);
      Navigator.push<bool>(context, MaterialPageRoute(builder: (_) =>
        PhotoCaptureScreen(worker: _worker, initialType: 'entrada')));
    },
  );
}
