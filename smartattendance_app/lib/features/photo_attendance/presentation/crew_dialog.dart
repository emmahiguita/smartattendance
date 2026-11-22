// ============================================================================
// ARCHIVO: crew_dialog.dart
// QUÉ HACE: Modal estilo iOS Inset Grouped para crear o editar un Equipo
//           ("Nuevo Equipo" / "Detalle de Cuadrilla") con resolución del
//           nombre del supervisor, puestos habilitados, sitio con dirección
//           real e integrantes asignados.
// CÓMO FUNCIONA: Utiliza `IosFloatingModal` con persistencia en `LocalAdminStore`.
// POR QUÉ: Gestión integral de puestos, equipos y dirección en iOS/Android (< 195 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../core/location/traccar_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/roles.dart';
import '../domain/photo_record.dart';
import 'local_providers.dart';
import 'widgets/crew_members_list.dart';
import 'widgets/crew_positions_section.dart';
import 'widgets/crew_zone_validity_section.dart';

class CrewDialog extends ConsumerStatefulWidget {
  const CrewDialog({super.key, this.crew, required this.zones});
  final Map<String, Object?>? crew;
  final List<Map<String, Object?>> zones;
  @override
  ConsumerState<CrewDialog> createState() => _CrewDialogState();
}

class _CrewDialogState extends ConsumerState<CrewDialog> {
  static const int _newZoneSentinel = -1;
  final _name = TextEditingController();
  final _supervisor = TextEditingController();
  final _alternate = TextEditingController();
  final _newZoneName = TextEditingController();
  final _newZoneAddress = TextEditingController();
  String? _from, _until, _error;
  int? _zone;
  bool _busy = false;
  List<String> _allPositions = List.of(AppRoles.operationalPositions);
  Set<String> _selectedPositions = {'Operador', 'Colaborador', 'Operario', 'Promotor'};
  final Map<int, String> _pendingRolesByWorkerId = {};

  @override
  void initState() {
    super.initState();
    final team = widget.crew;
    _from = DateTime.now().toIso8601String().split('T').first;
    _until = DateTime.now().add(const Duration(days: 365)).toIso8601String().split('T').first;
    if (team != null) {
      _name.text = team['name'] as String;
      _supervisor.text = team['supervisor_document'] as String;
      _alternate.text = team['driver_document'] as String? ?? '';
      _zone = team['zone_id'] as int?;
      _from = team['valid_from'] as String;
      _until = team['valid_until'] as String;
    } else {
      final actor = ref.read(localActorProvider);
      if (actor.document.trim().isNotEmpty) _supervisor.text = actor.document.trim();
      if (widget.zones.isNotEmpty) _zone = widget.zones.first['id'] as int?;
    }
    _loadPositions();
  }

  Future<void> _loadPositions() async {
    final store = ref.read(localAdminStoreProvider);
    final custom = await store.customJobPositions();
    final crewPos = await store.crewPositions(widget.crew?['id'] as int?);
    if (!mounted) return;
    setState(() {
      _allPositions = AppRoles.mergePositions(custom, includeManagement: false);
      _selectedPositions = crewPos.toSet();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _supervisor.dispose();
    _alternate.dispose();
    _newZoneName.dispose();
    _newZoneAddress.dispose();
    super.dispose();
  }

  Future<void> _pickSupervisor(List<LocalWorker> workers) async {
    if (workers.isEmpty) return;
    final chosen = await showCupertinoModalPopup<LocalWorker>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Seleccionar Supervisor / Encargado'),
        actions: [
          for (final w in workers)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, w),
              child: Text('${w.name} · ${w.job} (CC ${w.document})', style: const TextStyle(fontSize: 13.5)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
      ),
    );
    if (chosen != null && mounted) setState(() => _supervisor.text = chosen.document);
  }

  Future<void> _createPosition(String name) async {
    try {
      final updated = await ref.read(localAdminStoreProvider).addCustomJobPosition(name);
      if (!mounted) return;
      setState(() {
        _allPositions = AppRoles.mergePositions(updated, includeManagement: false);
        _selectedPositions.add(name.trim());
      });
    } catch (e) {
      if (mounted) setState(() => _error = e is FormatException ? e.message : 'No se pudo crear el puesto.');
    }
  }

  Future<void> _pickDate(bool start) async {
    final current = start ? _from : _until;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(current ?? '') ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final value = date.toIso8601String().split('T').first;
    setState(() => start ? _from = value : _until = value);
  }

  Future<void> _save() async {
    final actor = ref.read(localActorProvider);
    if (!actor.isStrictAdmin && actor.document.trim().isNotEmpty) _supervisor.text = actor.document.trim();
    if (_name.text.trim().isEmpty || _supervisor.text.trim().isEmpty) {
      setState(() => _error = 'Completa el nombre del equipo y cédula del supervisor.');
      return;
    }
    if (_selectedPositions.isEmpty) {
      setState(() => _error = 'Selecciona al menos un puesto laboral (Operador, Colaborador, Operario, etc.).');
      return;
    }
    setState(() => (_busy = true, _error = null));
    try {
      final store = ref.read(localAdminStoreProvider);
      int? targetZoneId = _zone;
      if (_zone == _newZoneSentinel || (_newZoneName.text.trim().isNotEmpty && _newZoneAddress.text.trim().isNotEmpty)) {
        final zName = _newZoneName.text.trim().isNotEmpty ? _newZoneName.text.trim() : 'Sitio ${_name.text.trim()}';
        final zAddr = _newZoneAddress.text.trim();
        if (zAddr.isEmpty) throw const FormatException('Ingresa la dirección física del sitio de trabajo.');
        final pt = await const TraccarService().geocodeAddress(zAddr);
        targetZoneId = await store.saveZone({
          'name': zName,
          'address': zAddr,
          'latitude': pt?.latitude ?? 4.8333,
          'longitude': pt?.longitude ?? -75.6833,
          'radius_m': 150.0,
        });
      }
      final savedCrewId = await store.saveCrew({
        'name': _name.text.trim(),
        'supervisor_document': _supervisor.text.trim(),
        'driver_document': _alternate.text.trim(),
        'zone_id': targetZoneId,
        'valid_from': _from,
        'valid_until': _until,
      }, id: widget.crew?['id'] as int?);

      await store.saveCrewPositions(savedCrewId, _selectedPositions.toList());
      for (final entry in _pendingRolesByWorkerId.entries) {
        await store.setWorkerCrew(entry.key, savedCrewId, role: entry.value);
      }
      ref.invalidate(localWorkersProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error is FormatException ? error.message : 'No se pudo guardar el equipo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.crew?['id'] as int?;
    if (id == null) return;
    setState(() => (_busy = true, _error = null));
    try {
      await ref.read(localAdminStoreProvider).deleteCrew(id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e is FormatException ? e.message : 'No se pudo eliminar el equipo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(localActorProvider);
    final workers = ref.watch(localWorkersProvider).valueOrNull ?? const [];
    final supWorker = workers.where((w) => w.document.trim() == _supervisor.text.trim()).firstOrNull;

    return PopScope(
      canPop: !_busy,
      child: IosFloatingModal(
        title: widget.crew == null ? 'Nuevo Equipo' : 'Detalle de Cuadrilla',
        isSaving: _busy,
        errorMessage: _error,
        onSave: _save,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          IosFormGroup(header: 'Datos de la Cuadrilla', children: [
            IosFormFieldRow(label: 'Equipo', placeholder: 'Ej. Cuadrilla Operativa Norte', controller: _name, textCapitalization: TextCapitalization.words),
            IosFormFieldRow(
              label: supWorker != null ? 'Supervisor (${supWorker.name.split(' ').first})' : 'Supervisor',
              placeholder: 'Cédula del encargado',
              controller: _supervisor,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              trailing: actor.isStrictAdmin && workers.isNotEmpty
                  ? GestureDetector(
                      onTap: () => _pickSupervisor(workers),
                      child: const Text('Elegir', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF007AFF))),
                    )
                  : null,
            ),
            IosFormFieldRow(label: 'Suplente', placeholder: 'Cédula adicional (opcional)', controller: _alternate, keyboardType: TextInputType.number),
          ]),
          const SizedBox(height: 10),
          CrewPositionsSection(
            allPositions: _allPositions,
            selectedPositions: _selectedPositions,
            isStrictAdmin: actor.isStrictAdmin,
            onTogglePosition: (pos) => setState(() {
              if (_selectedPositions.contains(pos) && _selectedPositions.length > 1) {
                _selectedPositions.remove(pos);
              } else {
                _selectedPositions.add(pos);
              }
            }),
            onCreatePosition: _createPosition,
          ),
          const SizedBox(height: 10),
          CrewZoneValiditySection(
            zones: widget.zones,
            selectedZoneId: _zone,
            newZoneSentinel: _newZoneSentinel,
            newZoneNameController: _newZoneName,
            newZoneAddressController: _newZoneAddress,
            validFrom: _from,
            validUntil: _until,
            busy: _busy,
            onZoneChanged: (v) => setState(() => _zone = v),
            onPickDate: _pickDate,
          ),
          CrewMembersList(
            crewId: widget.crew?['id'] as int?,
            availablePositions: _selectedPositions.toList(),
            pendingRolesByWorkerId: _pendingRolesByWorkerId,
            onAddPendingMember: (w, role) => setState(() => _pendingRolesByWorkerId[w.id] = role),
            onRemovePendingMember: (id) => setState(() => _pendingRolesByWorkerId.remove(id)),
          ),
          if (widget.crew != null) ...[
            const SizedBox(height: 14),
            CupertinoButton(
              color: AppColors.systemRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              padding: const EdgeInsets.symmetric(vertical: 10),
              onPressed: _busy ? null : _delete,
              child: const Text('Eliminar Cuadrilla', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.systemRed)),
            ),
          ],
        ]),
      ),
    );
  }
}
