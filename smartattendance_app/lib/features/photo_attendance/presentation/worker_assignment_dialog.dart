// ============================================================================
// ARCHIVO: worker_assignment_dialog.dart
// QUÉ HACE: Ventana flotante Apple iOS (`IosFloatingModal`) para que el
//           Administrador o Supervisor asigne Rol (`Colaborador`, `Supervisor`,
//           `Administrador`), Cuadrilla/Geocerca, Horario, Horas Extras
//           Asignadas (`assignedOvertimeMinutes`) o dé de baja a un usuario.
// CÓMO FUNCIONA: Persiste cambios en `LocalAdminStore` sincronizando el login,
//                el horario base y las horas extras pre-asignadas.
// POR QUÉ: Permite asignar horas extras y administrar permisos desde adentro
//          cumpliendo < 195 líneas.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/photo_record.dart';
import '../domain/shift_template.dart';
import '../domain/work_schedule.dart';
import 'local_providers.dart';

class WorkerAssignmentDialog extends ConsumerStatefulWidget {
  const WorkerAssignmentDialog({super.key, required this.worker});
  final LocalWorker worker;
  @override
  ConsumerState<WorkerAssignmentDialog> createState() => _WorkerAssignmentDialogState();
}

class _WorkerAssignmentDialogState extends ConsumerState<WorkerAssignmentDialog> {
  final _reference = TextEditingController();
  List<Map<String, Object?>> _teams = [];
  List<ShiftTemplate> _templates = [];
  int? _team;
  WorkSchedule? _schedule;
  int _overtimeMinutes = 0;
  late String _role = widget.worker.job.isNotEmpty ? widget.worker.job : 'Colaborador';
  bool _loading = true, _busy = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final store = ref.read(localAdminStoreProvider);
      await store.ensureDefaultData();
      final teams = await store.crewsWithZones();
      final templates = await store.shiftTemplates();
      final worker = await store.workerConfig(widget.worker.id);
      if (!mounted) return;
      _schedule = WorkSchedule.decode(worker['schedule_json'] as String?);
      _overtimeMinutes = _schedule?.assignedOvertimeMinutes ?? 0;
      _team = worker['crew_id'] as int?;
      _role = (worker['job'] as String?)?.trim().isNotEmpty == true ? worker['job'] as String : 'Colaborador';
      _reference.text = worker['authorization_reference'] as String? ?? 'Autorización firmada en expediente RRHH';
      _teams = teams;
      _templates = templates;
    } catch (_) {
      if (mounted) _error = 'No se pudo cargar la configuración.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => (_busy = true, _error = null));
    try {
      final baseSched = _schedule ?? (_overtimeMinutes > 0 ? const WorkSchedule(480, true, shiftName: 'Jornada Estándar', startMinute: 480, endMinute: 1020) : null);
      final finalSched = baseSched?.copyWith(assignedOvertimeMinutes: _overtimeMinutes);
      await ref.read(localAdminStoreProvider).assignWorker(widget.worker.id, _team, finalSched, _reference.text, role: _role);
      ref.invalidate(localWorkersProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error is FormatException ? error.message : 'No se pudo guardar.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Eliminar / Dar de Baja'),
        content: Text('¿Deseas eliminar a "${widget.worker.name}" ($_role)? Ya no podrá iniciar sesión con su cédula.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          CupertinoDialogAction(isDestructiveAction: true, onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => (_busy = true, _error = null));
    try {
      await ref.read(localAdminStoreProvider).deleteWorker(widget.worker.id);
      ref.invalidate(localWorkersProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => (_error = e is FormatException ? e.message : 'No se pudo eliminar.', _busy = false));
    }
  }

  Future<void> _pickRole() async {
    const roles = [
      ('Colaborador', 'Solo marca ingreso, almuerzo y salida (sin acceso a RRHH)'),
      ('Supervisor', 'Inicia sesión con permisos de supervisión de cuadrilla y RRHH'),
      ('Administrador', 'Inicia sesión con control total de horarios, zonas y reportes'),
    ];
    final selected = await showIosGlassFloatingMenu<String>(
      context: context, title: 'Rol y Nivel de Permisos', subtitle: 'Define con qué permisos iniciará sesión',
      actions: [for (final r in roles) IosGlassAction<String>(label: r.$1, subtitle: r.$2, value: r.$1, icon: r.$1 == 'Colaborador' ? CupertinoIcons.person : CupertinoIcons.shield_lefthalf_fill)],
    );
    if (mounted && selected != null) setState(() => _role = selected);
  }

  Future<void> _pickTeam() async {
    final actions = [
      const IosGlassAction<int?>(label: 'Sin equipo asignado (Zona Libre)', value: null, icon: CupertinoIcons.clear_circled),
      for (final t in _teams) IosGlassAction<int?>(label: t['name'] as String, subtitle: t['zone_name'] != null ? '${t['zone_name']}' : null, value: t['id'] as int, icon: CupertinoIcons.person_2_fill),
    ];
    final selected = await showIosGlassFloatingMenu<int?>(context: context, title: 'Equipo y Geocerca', subtitle: 'Selecciona la cuadrilla y geocerca', actions: actions);
    if (mounted && selected != _team) setState(() => _team = selected);
  }

  Future<void> _pickSchedule() async {
    final actions = [
      for (final t in _templates) IosGlassAction<WorkSchedule?>(label: t.name, subtitle: t.timeFormatted, value: t.toSchedule().copyWith(assignedOvertimeMinutes: _overtimeMinutes), icon: CupertinoIcons.clock),
      const IosGlassAction<WorkSchedule?>(label: 'Sin horario fijo', subtitle: 'Horario flexible', value: null, icon: CupertinoIcons.slash_circle, isDestructive: true),
    ];
    final selected = await showIosGlassFloatingMenu<WorkSchedule?>(context: context, title: 'Horario Pactado', subtitle: 'Selecciona la plantilla de turno', actions: actions);
    if (mounted) setState(() => _schedule = selected);
  }

  Future<void> _pickOvertime() async {
    const opts = [(0, 'Sin horas extras'), (60, '+1 Hora Extra asignada'), (120, '+2 Horas Extras asignadas'), (180, '+3 Horas Extras asignadas'), (240, '+4 Horas Extras asignadas')];
    final selected = await showIosGlassFloatingMenu<int>(
      context: context, title: 'Horas Extras Asignadas', subtitle: 'Se contabilizan al cumplir el horario o marcar salida de extras',
      actions: [for (final o in opts) IosGlassAction<int>(label: o.$2, value: o.$1, icon: CupertinoIcons.bolt_badge_a_fill)],
    );
    if (mounted && selected != null) setState(() => _overtimeMinutes = selected);
  }

  @override
  void dispose() { _reference.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sel = _teams.where((t) => t['id'] == _team).firstOrNull;
    final teamName = sel != null ? (sel['zone_name'] != null ? '${sel['name']} (${sel['zone_name']})' : sel['name'] as String) : 'Sin equipo asignado';
    final scheduleLabel = _schedule != null ? (_schedule!.shiftName ?? _schedule!.timeWindowFormatted) : 'Sin horario fijo';
    final overtimeLabel = _overtimeMinutes > 0 ? '+${_overtimeMinutes ~/ 60}h Extras Asignadas' : 'Sin horas extras';

    return IosFloatingModal(
      title: widget.worker.name, saveLabel: 'Guardar', isSaving: _busy || _loading, errorMessage: _error, onSave: _save,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        IosFormGroup(header: 'ROL, EQUIPO, HORARIO Y HORAS EXTRAS', children: [
          _rowPicker(context, 'Rol / Acceso', _role, _pickRole),
          _rowPicker(context, 'Equipo / Zona', teamName, _pickTeam),
          _rowPicker(context, 'Horario', scheduleLabel, _pickSchedule),
          _rowPicker(context, 'Horas Extras', overtimeLabel, _pickOvertime),
          IosFormFieldRow(label: 'Soporte', placeholder: 'Referencia RRHH', controller: _reference),
        ]),
        const SizedBox(height: 12),
        if (widget.worker.document.trim() != '1007331963')
          CupertinoButton(
            color: AppColors.systemRed.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10), padding: const EdgeInsets.symmetric(vertical: 10),
            onPressed: _busy ? null : _deleteUser,
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(CupertinoIcons.trash, size: 15, color: AppColors.systemRed), SizedBox(width: 6), Text('Eliminar Usuario / Dar de Baja', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.systemRed))]),
          ),
      ]),
    );
  }

  Widget _rowPicker(BuildContext context, String label, String value, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            SizedBox(width: 96, child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.cTextPrimary))),
            Expanded(child: Text(value, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary))),
            const SizedBox(width: 6),
            Icon(CupertinoIcons.chevron_forward, size: 14, color: context.cTextSecondary),
          ]),
        ),
      );
}
