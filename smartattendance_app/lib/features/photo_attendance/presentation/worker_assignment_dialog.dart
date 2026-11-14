// ============================================================================
// ARCHIVO: worker_assignment_dialog.dart
// QUÉ HACE: Ventana flotante Apple iOS (`IosFloatingModal`) para que el
//           Administrador o Supervisor asigne Puesto (`Operador`, `Colaborador`,
//           `Operario`, `Supervisor`, `Administrador`, etc.), Equipo, Sitio de
//           Trabajo con Dirección Real, Horario y Horas Extras Asignadas.
// CÓMO FUNCIONA: Persiste cambios en `LocalAdminStore` sincronizando el login,
//                la cuadrilla, la geocerca/dirección del sitio y el horario.
// POR QUÉ: Garantiza que desde la ficha de cualquier colaborador se pueda
//          asignar puesto, equipo y sitio de trabajo con dirección (< 230 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../core/location/traccar_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/roles.dart';
import '../domain/photo_record.dart';
import '../domain/shift_template.dart';
import '../domain/work_schedule.dart';
import 'crew_dialog.dart';
import 'local_providers.dart';

class WorkerAssignmentDialog extends ConsumerStatefulWidget {
  const WorkerAssignmentDialog({super.key, required this.worker});
  final LocalWorker worker;
  @override
  ConsumerState<WorkerAssignmentDialog> createState() => _WorkerAssignmentDialogState();
}

class _WorkerAssignmentDialogState extends ConsumerState<WorkerAssignmentDialog> {
  final _reference = TextEditingController();
  final _siteName = TextEditingController();
  final _siteAddress = TextEditingController();
  List<Map<String, Object?>> _teams = [];
  List<Map<String, Object?>> _zones = [];
  List<ShiftTemplate> _templates = [];
  List<String> _customPositions = [];
  int? _team;
  WorkSchedule? _schedule;
  int _overtimeMinutes = 0;
  late String _role = widget.worker.job.isNotEmpty ? widget.worker.job : 'Operador';
  bool _loading = true, _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final store = ref.read(localAdminStoreProvider);
      await store.ensureDefaultData();
      final teams = await store.crewsWithZones();
      final zones = await store.rows('work_zones');
      final templates = await store.shiftTemplates();
      final customPos = await store.customJobPositions();
      final worker = await store.workerConfig(widget.worker.id);
      if (!mounted) return;
      _schedule = WorkSchedule.decode(worker['schedule_json'] as String?);
      _overtimeMinutes = _schedule?.assignedOvertimeMinutes ?? 0;
      _team = worker['crew_id'] as int?;
      _role = (worker['job'] as String?)?.trim().isNotEmpty == true ? worker['job'] as String : 'Operador';
      _reference.text = worker['authorization_reference'] as String? ?? 'Autorización firmada en expediente RRHH';
      _teams = teams;
      _zones = zones;
      _templates = templates;
      _customPositions = customPos;
      _syncSiteFieldsFromTeam(_team);
    } catch (_) {
      if (mounted) _error = 'No se pudo cargar la configuración.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _syncSiteFieldsFromTeam(int? teamId) {
    final sel = _teams.where((t) => t['id'] == teamId).firstOrNull;
    if (sel != null) {
      _siteName.text = (sel['zone_name'] as String?) ?? '';
      _siteAddress.text = (sel['zone_address'] as String?) ?? '';
    }
  }

  Future<void> _save() async {
    setState(() => (_busy = true, _error = null));
    try {
      final store = ref.read(localAdminStoreProvider);
      final sName = _siteName.text.trim();
      final sAddr = _siteAddress.text.trim();
      if (_team != null && (sName.isNotEmpty || sAddr.isNotEmpty)) {
        final currentCrew = _teams.where((t) => t['id'] == _team).firstOrNull;
        if (currentCrew != null) {
          final existingZoneId = currentCrew['zone_id'] as int?;
          final pt = sAddr.isNotEmpty ? await const TraccarService().geocodeAddress(sAddr) : null;
          final lat = pt?.latitude ?? (currentCrew['zone_lat'] as num?)?.toDouble() ?? 4.8333;
          final lng = pt?.longitude ?? (currentCrew['zone_lng'] as num?)?.toDouble() ?? -75.6833;
          final zoneId = await store.saveZone({
            'name': sName.isNotEmpty ? sName : 'Sitio ${currentCrew['name']}',
            'address': sAddr,
            'latitude': lat,
            'longitude': lng,
            'radius_m': (currentCrew['zone_radius'] as num?)?.toDouble() ?? 150.0,
          }, id: existingZoneId);
          await store.saveCrew({
            'name': currentCrew['name'],
            'supervisor_document': currentCrew['supervisor_document'],
            'driver_document': currentCrew['driver_document'] ?? '',
            'zone_id': zoneId,
            'valid_from': currentCrew['valid_from'],
            'valid_until': currentCrew['valid_until'],
          }, id: _team);
        }
      }

      final baseSched = _schedule ?? (_overtimeMinutes > 0 ? const WorkSchedule(480, true, shiftName: 'Jornada Estándar', startMinute: 480, endMinute: 1020) : null);
      final finalSched = baseSched?.copyWith(assignedOvertimeMinutes: _overtimeMinutes);
      await store.assignWorker(widget.worker.id, _team, finalSched, _reference.text, role: _role);
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
    final isStrictAdmin = ref.read(localActorProvider).isStrictAdmin;
    final positions = AppRoles.allowedAssignableRoles(
      isStrictAdminUser: isStrictAdmin,
      customPositions: _customPositions,
    );
    final selected = await showIosGlassFloatingMenu<String>(
      context: context,
      title: 'Puesto y Nivel de Permisos',
      subtitle: 'Selecciona Operador, Colaborador, Operario u otro puesto',
      actions: [
        for (final pos in positions)
          IosGlassAction<String>(
            label: pos,
            subtitle: AppRoles.descriptionFor(pos),
            value: pos,
            icon: AppRoles.isStrictAdmin(pos)
                ? Icons.manage_accounts_rounded
                : (AppRoles.isSupervisorOrManager(pos) ? Icons.engineering_rounded : CupertinoIcons.person_fill),
          ),
      ],
    );
    if (mounted && selected != null) setState(() => _role = selected);
  }

  Future<void> _pickTeam() async {
    final actions = [
      const IosGlassAction<int?>(label: 'Sin equipo asignado (Zona Libre)', value: null, icon: CupertinoIcons.clear_circled),
      for (final t in _teams)
        IosGlassAction<int?>(
          label: t['name'] as String,
          subtitle: t['zone_name'] != null ? '${t['zone_name']} · ${t['zone_address'] ?? ''}' : 'Sin sitio asignado',
          value: t['id'] as int,
          icon: CupertinoIcons.person_2_fill,
        ),
      const IosGlassAction<int?>(
        label: '+ Crear Nuevo Equipo con Puestos y Sitio…',
        value: -1,
        icon: CupertinoIcons.add_circled_solid,
      ),
    ];
    final selected = await showIosGlassFloatingMenu<int?>(
      context: context,
      title: 'Equipo y Geocerca',
      subtitle: 'Selecciona la cuadrilla o crea una nueva',
      actions: actions,
    );
    if (!mounted) return;
    if (selected == -1) {
      final created = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => CrewDialog(zones: _zones));
      if (created == true && mounted) await _load();
      return;
    }
    if (selected != _team) {
      setState(() {
        _team = selected;
        _syncSiteFieldsFromTeam(selected);
      });
    }
  }

  Future<void> _pickSchedule() async {
    final actions = [
      for (final t in _templates) IosGlassAction<WorkSchedule?>(label: t.name, subtitle: t.timeFormattedDual, value: t.toSchedule().copyWith(assignedOvertimeMinutes: _overtimeMinutes), icon: CupertinoIcons.clock),
      const IosGlassAction<WorkSchedule?>(label: 'Sin horario fijo', subtitle: 'Horario flexible', value: null, icon: CupertinoIcons.slash_circle, isDestructive: true),
    ];
    final selected = await showIosGlassFloatingMenu<WorkSchedule?>(context: context, title: 'Horario Pactado', subtitle: 'Selecciona la plantilla de turno', actions: actions);
    if (mounted) setState(() => _schedule = selected);
  }

  Future<void> _pickOvertime() async {
    const opts = [(0, 'Sin horas extras'), (60, '+1 Hora Extra asignada'), (120, '+2 Horas Extras asignadas'), (180, '+3 Horas Extras asignadas'), (240, '+4 Horas Extras asignadas')];
    final selected = await showIosGlassFloatingMenu<int>(
      context: context,
      title: 'Horas Extras Asignadas',
      subtitle: 'Se contabilizan al cumplir el horario o marcar salida de extras',
      actions: [for (final o in opts) IosGlassAction<int>(label: o.$2, value: o.$1, icon: CupertinoIcons.bolt_badge_a_fill)],
    );
    if (mounted && selected != null) setState(() => _overtimeMinutes = selected);
  }

  @override
  void dispose() {
    _reference.dispose();
    _siteName.dispose();
    _siteAddress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sel = _teams.where((t) => t['id'] == _team).firstOrNull;
    final teamName = sel != null ? (sel['zone_name'] != null ? '${sel['name']} (${sel['zone_name']})' : sel['name'] as String) : 'Sin equipo asignado';
    final scheduleLabel = _schedule != null ? (_schedule!.shiftName ?? _schedule!.timeWindowFormatted) : 'Sin horario fijo';
    final overtimeLabel = _overtimeMinutes > 0 ? '+${_overtimeMinutes ~/ 60}h Extras Asignadas' : 'Sin horas extras';

    return IosFloatingModal(
      title: widget.worker.name,
      saveLabel: 'Guardar',
      isSaving: _busy || _loading,
      errorMessage: _error,
      onSave: _save,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        IosFormGroup(header: 'PUESTO, EQUIPO, SITIO CON DIRECCIÓN Y HORARIO', children: [
          _rowPicker(context, 'Puesto / Rol', _role, _pickRole),
          _rowPicker(context, 'Equipo', teamName, _pickTeam),
          if (_team != null) ...[
            IosFormFieldRow(label: 'Sitio trabajo', placeholder: 'Ej. Planta Acueducto', controller: _siteName, textCapitalization: TextCapitalization.words),
            IosFormFieldRow(label: 'Dirección', placeholder: 'Ej. Calle 25 # 20-30, Dosquebradas', controller: _siteAddress, textCapitalization: TextCapitalization.sentences),
          ],
          _rowPicker(context, 'Horario', scheduleLabel, _pickSchedule),
          _rowPicker(context, 'Horas Extras', overtimeLabel, _pickOvertime),
          IosFormFieldRow(label: 'Soporte', placeholder: 'Referencia RRHH', controller: _reference),
        ]),
        const SizedBox(height: 12),
        if (widget.worker.document.trim() != ref.watch(localActorProvider).document.trim())
          CupertinoButton(
            color: AppColors.systemRed.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            padding: const EdgeInsets.symmetric(vertical: 10),
            onPressed: _busy ? null : _deleteUser,
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(CupertinoIcons.trash, size: 15, color: AppColors.systemRed),
              SizedBox(width: 6),
              Text('Eliminar Usuario / Dar de Baja', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.systemRed)),
            ]),
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
            Expanded(child: Text(value, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.cTextPrimary))),
            const SizedBox(width: 6),
            Icon(CupertinoIcons.chevron_forward, size: 14, color: context.cTextSecondary),
          ]),
        ),
      );
}
