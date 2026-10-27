// ============================================================================
// ARCHIVO: worker_hr_management_sheet.dart
// QUÉ HACE: Hoja modal estilo Apple iOS Inset Grouped para gestionar a un
//           colaborador individual: Equipo/Cuadrilla, Zona GPS, Horario
//           pactado (`WorkSchedule`), liquidación de Horas Extras y marcación
//           biométrica asistida.
// CÓMO FUNCIONA: Muestra los datos de `LocalWorker`, permite abrir la ventana
//                flotante `WorkerAssignmentDialog` y audita la última jornada.
// POR QUÉ: Sustituye cajas Material por secciones iOS limpias (< 170 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/work_schedule.dart';
import '../../../photo_attendance/presentation/local_providers.dart';
import '../../../photo_attendance/presentation/photo_capture_screen.dart';
import '../../../photo_attendance/presentation/worker_assignment_dialog.dart';
import 'staff_status_types.dart';
import 'worker_hr_overtime_section.dart';

class WorkerHrManagementSheet extends ConsumerStatefulWidget {
  const WorkerHrManagementSheet({super.key, required this.worker});
  final LocalWorker worker;

  static Future<void> show(BuildContext context, {required LocalWorker worker}) =>
      showIosFloatingGlassSheet(
        context: context,
        title: 'Gestión Laboral y Turno',
        subtitle: worker.name,
        child: WorkerHrManagementSheet(worker: worker),
      );

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

  Future<void> _loadLatestDay() async {
    setState(() => _loadingDay = true);
    try {
      final days = await ref.read(localPhotoRepositoryProvider).days(search: _worker.document, limit: 1);
      if (mounted) setState(() => (_latestDay = days.isNotEmpty ? days.first : null, _loadingDay = false));
    } catch (_) {
      if (mounted) setState(() => _loadingDay = false);
    }
  }

  Future<void> _openAssignmentDialog() async {
    final updated = await showDialog<bool>(context: context, builder: (_) => WorkerAssignmentDialog(worker: _worker));
    if (updated == true && mounted) {
      ref.invalidate(localWorkersProvider);
      ref.invalidate(allOvertimeDaysProvider);
      final list = await ref.read(localPhotoRepositoryProvider).workers();
      final fresh = list.firstWhere((w) => w.id == _worker.id, orElse: () => _worker);
      if (mounted) {
        setState(() => _worker = fresh);
        _loadLatestDay();
      }
    }
  }

  Future<void> _reviewOvertime(bool approve) async {
    final day = _latestDay;
    if (day == null || _reviewing) return;
    setState(() => _reviewing = true);
    try {
      await ref.read(localAdminStoreProvider).review(day, approve: approve, abandon: false);
      ref.invalidate(allOvertimeDaysProvider);
      if (mounted) {
        setState(() => _message = approve ? 'Horas extras aprobadas por el Administrador' : 'Tiempo adicional rechazado');
        await _loadLatestDay();
      }
    } catch (e) {
      if (mounted) setState(() => _message = e is FormatException ? e.message : 'Error al registrar revisión');
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  Future<void> _applyScheduleToDay() async {
    final day = _latestDay;
    if (day == null || _reviewing) return;
    setState(() => _reviewing = true);
    try {
      await ref.read(localAdminStoreProvider).applySchedule(day);
      ref.invalidate(allOvertimeDaysProvider);
      if (mounted) {
        setState(() => _message = 'Jornada pactada vinculada al registro');
        await _loadLatestDay();
      }
    } finally {
      if (mounted) setState(() => _reviewing = false);
    }
  }

  Future<void> _deleteWorker() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Dar de Baja Colaborador'),
        content: Text('¿Deseas desvincular a "${_worker.name}" de la nómina y registros locales?'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(ctx, true), child: const Text('Desvincular')),
        ],
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = calculateStaffStatus(_worker, ColombiaClock.day(DateTime.now()));
    final initial = _worker.name.trim().isEmpty ? '?' : _worker.name.trim()[0].toUpperCase();
    final scheduleLabel = _worker.schedule != null ? (_worker.schedule!.shiftName ?? _worker.schedule!.timeWindowFormatted) : 'Sin horario asignado';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
              CircleAvatar(radius: 21, backgroundColor: AppColors.primary.withValues(alpha: 0.14), child: Text(initial, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_worker.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.cTextPrimary)),
                  Text('${_worker.job} · C.C. ${_worker.document}', style: TextStyle(fontSize: 12, color: context.cTextSecondary)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: status.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                child: Text(status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: status.color)),
              ),
            ]),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(_message!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
            const SizedBox(height: 14),
            IosFormGroup(
              header: 'ASIGNACIÓN OPERATIVA Y REGLAS',
              children: [
                _infoRow(context, 'Horario pactado', scheduleLabel, onTap: _openAssignmentDialog),
                _infoRow(context, 'Equipo / Cuadrilla', _worker.crewName ?? 'Sin equipo', onTap: _openAssignmentDialog),
                _infoRow(context, 'Geocerca GPS', _worker.zoneName ?? 'Sin geocerca', onTap: _openAssignmentDialog),
              ],
            ),
            const SizedBox(height: 14),
            IosFormGroup(
              header: 'AUDITORÍA DE ÚLTIMA JORNADA Y EXTRAS',
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: WorkerHrOvertimeSection(latestDay: _latestDay, loading: _loadingDay, reviewing: _reviewing, isDark: isDark, onApplySchedule: _applyScheduleToDay, onReviewOvertime: _reviewOvertime),
                ),
              ],
            ),
            const SizedBox(height: 14),
            CupertinoButton(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(11),
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => PhotoCaptureScreen(worker: _worker, initialType: 'entrada')));
              },
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(CupertinoIcons.viewfinder, size: 17, color: Colors.white),
                SizedBox(width: 8),
                Text('Registrar Asistencia Facial', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 12),
            CupertinoButton(
              color: AppColors.systemRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
              padding: const EdgeInsets.symmetric(vertical: 10),
              onPressed: _deleteWorker,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.person_badge_minus, size: 16, color: AppColors.systemRed),
                  SizedBox(width: 6),
                  Text('Desvincular de Nómina / Dar de Baja', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.systemRed)),
                ],
              ),
            ),
          ]),
        );
  }

  Widget _infoRow(BuildContext context, String label, String value, {required VoidCallback onTap}) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.cTextPrimary)),
            const SizedBox(width: 10),
            Expanded(child: Text(value, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary))),
            const SizedBox(width: 4),
            Icon(CupertinoIcons.chevron_forward, size: 14, color: context.cTextSecondary),
          ]),
        ),
      );
}
