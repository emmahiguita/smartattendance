// ============================================================================
// ARCHIVO: consolidated_edit_sheet.dart
// CAPA: Presentation / Consolidated / Widgets
// QUÉ HACE: Modal para crear o editar la información completa de la asistencia.
// CÓMO FUNCIONA: Orquesta fecha, entrada, salida, sede, estado, extras y motivo.
//                Si `record == null`, crea un registro nuevo en SQLite (`journeys`).
// POR QUÉ: Permite corregir o registrar asistencias reales con estética iOS < 200 líneas.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../controllers/consolidated_attendance_controller.dart';
import '../models/consolidated_record.dart';
import 'consolidated_edit_admin_section.dart';
import 'consolidated_edit_time_section.dart';

class ConsolidatedEditSheet extends StatefulWidget {
  const ConsolidatedEditSheet({
    super.key,
    required this.record,
    required this.controller,
    required this.availableZones,
  });

  final ConsolidatedRecord? record;
  final ConsolidatedAttendanceController controller;
  final List<String> availableZones;

  @override
  State<ConsolidatedEditSheet> createState() => _ConsolidatedEditSheetState();
}

class _ConsolidatedEditSheetState extends State<ConsolidatedEditSheet> {
  late DateTime _selectedDate;
  TimeOfDay? _entradaTime;
  TimeOfDay? _salidaTime;
  late String _selectedZone;
  late String _selectedStatus;
  int? _selectedWorkerId;
  late final TextEditingController _reasonCtrl;
  late final TextEditingController _extrasMinutesCtrl;
  List<Map<String, dynamic>> _workers = const [];
  bool _isSaving = false;
  String? _errorText;

  bool get _isCreateMode => widget.record == null;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _selectedDate = r?.fecha ?? DateTime.now();
    if (r?.entradaDateTime != null) {
      _entradaTime = TimeOfDay.fromDateTime(r!.entradaDateTime!.toLocal());
    } else if (_isCreateMode) {
      _entradaTime = const TimeOfDay(hour: 7, minute: 0);
    }
    if (r?.salidaDateTime != null) {
      _salidaTime = TimeOfDay.fromDateTime(r!.salidaDateTime!.toLocal());
    } else if (_isCreateMode) {
      _salidaTime = const TimeOfDay(hour: 16, minute: 0);
    }
    _selectedZone = r?.zona ?? (widget.availableZones.firstOrNull ?? 'Planta Operativa Dosquebradas');
    _selectedStatus = r?.estado ?? 'Cerrada';
    _selectedWorkerId = r?.workerId;
    _extrasMinutesCtrl = TextEditingController(text: '${((r?.approvedSeconds ?? 0) ~/ 60)}');
    _reasonCtrl = TextEditingController(
      text: r?.reviewNote ?? (_isCreateMode ? 'Registro administrativo de asistencia' : ''),
    );

    widget.controller.getWorkers().then((list) {
      if (!mounted) return;
      setState(() {
        _workers = list;
        if (_selectedWorkerId == null && list.isNotEmpty) {
          _selectedWorkerId = list.first['id'] as int?;
        }
      });
    });
  }

  @override
  void dispose() {
    _extrasMinutesCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  /// QUÉ HACE: Valida y persiste la edición o creación manual en SQLite.
  /// CÓMO: Captura `ScaffoldMessenger.maybeOf(context)` antes de `Navigator.pop`.
  /// POR QUÉ: Evita usar un `BuildContext` desmontado tras cerrar el modal.
  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorText = 'Ingresa el motivo o justificación de la operación.');
      return;
    }
    final minutes = int.tryParse(_extrasMinutesCtrl.text.trim()) ?? 0;
    if (minutes < 0 || minutes > 960) {
      setState(() => _errorText = 'Minutos fuera de rango válido (0 a 960).');
      return;
    }
    if (_isCreateMode && (_selectedWorkerId == null || _entradaTime == null)) {
      setState(() => _errorText = 'Selecciona un colaborador y la hora de entrada.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final messenger = ScaffoldMessenger.maybeOf(context);
    final rawStatus = _selectedStatus == 'Anulada' ? 'void' : (_selectedStatus == 'Cerrada' ? 'closed' : 'open');
    final bool success;
    if (_isCreateMode) {
      success = await widget.controller.createManualRecord(
        workerId: _selectedWorkerId!,
        workDate: _selectedDate,
        entradaTime: _entradaTime!,
        salidaTime: _salidaTime,
        zoneName: _selectedZone,
        status: rawStatus,
        approvedSeconds: minutes > 0 ? minutes * 60 : null,
        reason: reason,
      );
    } else {
      success = await widget.controller.saveCorrection(
        journeyId: widget.record!.journeyId,
        newZone: _selectedZone,
        newStatus: rawStatus,
        newApprovedSeconds: minutes > 0 ? minutes * 60 : null,
        reason: reason,
        newDate: _selectedDate,
        newEntradaTime: _entradaTime,
        newSalidaTime: _salidaTime,
        newWorkerId: _selectedWorkerId,
      );
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context, true);
        messenger?.showSnackBar(
          SnackBar(
            content: Text(_isCreateMode ? 'Asistencia registrada con éxito.' : 'Información actualizada con éxito.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _errorText = 'No se pudo guardar en la base de datos local.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final isDark = context.isDark;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 14, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isCreateMode ? 'Registrar Asistencia Manual' : 'Editar Asistencia Completa',
                        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: context.cTextPrimary),
                      ),
                      Text(
                        r != null ? '${r.colaborador} · CC ${r.cedula}' : 'Selecciona el colaborador, sede y horario',
                        style: TextStyle(fontSize: 12, color: context.cTextSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(CupertinoIcons.clear_circled_solid, size: 22),
                  color: context.cTextSecondary,
                ),
              ],
            ),
            const Divider(height: 18),
            ConsolidatedEditTimeSection(
              selectedDate: _selectedDate,
              entradaTime: _entradaTime,
              salidaTime: _salidaTime,
              onDateChanged: (d) => setState(() => _selectedDate = d),
              onEntradaChanged: (t) => setState(() => _entradaTime = t),
              onSalidaChanged: (t) => setState(() {
                _salidaTime = t;
                if (t != null && _selectedStatus == 'Abierta') _selectedStatus = 'Cerrada';
              }),
            ),
            const SizedBox(height: 12),
            ConsolidatedEditAdminSection(
              selectedZone: _selectedZone,
              selectedStatus: _selectedStatus,
              availableZones: widget.availableZones,
              extrasCtrl: _extrasMinutesCtrl,
              reasonCtrl: _reasonCtrl,
              workers: _workers,
              selectedWorkerId: _selectedWorkerId,
              onWorkerChanged: (id) => setState(() => _selectedWorkerId = id),
              onZoneChanged: (z) => setState(() => _selectedZone = z),
              onStatusChanged: (s) => setState(() => _selectedStatus = s),
            ),
            if (r?.reviewedBy != null) ...[
              const SizedBox(height: 8),
              Text(
                'Auditado por ${r!.reviewedBy} (${r.reviewedAt ?? ''})',
                style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: context.cTextSecondary),
              ),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                style: TextStyle(fontSize: 11.5, color: isDark ? Colors.red.shade300 : Colors.red.shade700, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white))
                        : Text(_isCreateMode ? 'Registrar Asistencia' : 'Guardar Información', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
