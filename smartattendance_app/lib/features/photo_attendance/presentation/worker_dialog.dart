// ============================================================================
// ARCHIVO: worker_dialog.dart
// QUÉ HACE: Modal flotante iOS para alta de colaboradores por el Administrador,
//           asignando Turno, Ventana de Marcación, Cuadrilla y captura de
//           coordenadas GPS reales del móvil para la zona de trabajo.
// CÓMO FUNCIONA: Usa `LocationService` para capturar la posición real del móvil,
//                asocia plantilla de horario y persiste en SQLite.
// POR QUÉ: Satisface la regla de negocio del administrador (< 190 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../core/location/location_service.dart';
import '../domain/shift_template.dart';
import '../domain/work_schedule.dart';
import 'local_providers.dart';
import 'worker_dialog_fields.dart';

/// Componente modal para afiliar un nuevo colaborador con turno y geocerca.
class WorkerDialog extends ConsumerStatefulWidget {
  const WorkerDialog({super.key});
  @override
  ConsumerState<WorkerDialog> createState() => _WorkerDialogState();
}

class _WorkerDialogState extends ConsumerState<WorkerDialog> {
  final _name = TextEditingController();
  final _document = TextEditingController();
  final _job = TextEditingController(text: 'Operario');
  List<Map<String, Object?>> _teams = [];
  List<ShiftTemplate> _templates = [];
  int? _crewId;
  String? _crewName;
  ShiftTemplate? _selectedTemplate;
  String _toleranceMode = 'Turno exacto';
  double? _gpsLat, _gpsLng;
  bool _saving = false, _locating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  /// QUÉ HACE: Carga cuadrillas y plantillas de turno desde SQLite.
  Future<void> _loadMetadata() async {
    try {
      final store = ref.read(localAdminStoreProvider);
      await store.ensureDefaultData();
      final teams = await store.rows('crews');
      final templates = await store.shiftTemplates();
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _templates = templates;
        if (teams.isNotEmpty) {
          _crewId = teams.first['id'] as int?;
          _crewName = teams.first['name'] as String?;
        }
        if (templates.isNotEmpty) _selectedTemplate = templates.first;
      });
    } catch (_) {}
  }

  /// QUÉ HACE: Captura las coordenadas GPS reales del dispositivo actual.
  Future<void> _captureGps() async {
    setState(() => _locating = true);
    try {
      final loc = await const LocationService().capture();
      if (!mounted) return;
      setState(() {
        if (loc != null) { _gpsLat = loc.lat; _gpsLng = loc.lng; }
        else { _error = 'No se obtuvo señal GPS en este móvil.'; }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Error capturando GPS: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// QUÉ HACE: Abre el selector flotante de plantilla de turno.
  Future<void> _pickSchedule() async {
    final selected = await showIosGlassFloatingMenu<ShiftTemplate>(
      context: context,
      title: 'Horario y Turno Asignado',
      subtitle: 'Selecciona la jornada laboral predefinida',
      actions: [for (final t in _templates) IosGlassAction<ShiftTemplate>(label: t.name, subtitle: t.timeFormatted, value: t, icon: CupertinoIcons.clock)],
    );
    if (mounted && selected != null) setState(() => _selectedTemplate = selected);
  }

  /// QUÉ HACE: Abre el selector de ventana de tolerancia horaria para marcar.
  Future<void> _pickTolerance() async {
    const opts = ['Turno exacto', 'Tolerancia ±30 min', 'Tolerancia ±60 min', 'Sin límite de hora'];
    final selected = await showIosGlassFloatingMenu<String>(
      context: context,
      title: 'Rango de Marcación Permitido',
      subtitle: 'Ventana de flexibilidad horaria autorizada',
      actions: [for (final opt in opts) IosGlassAction<String>(label: opt, value: opt, icon: CupertinoIcons.timer)],
    );
    if (mounted && selected != null) setState(() => _toleranceMode = selected);
  }

  /// QUÉ HACE: Abre el selector flotante de cuadrilla operativa.
  Future<void> _pickCrew() async {
    if (_teams.isEmpty) return;
    final selected = await showIosGlassFloatingMenu<Map<String, Object?>>(
      context: context,
      title: 'Asignar a Cuadrilla',
      subtitle: 'Equipo de trabajo asignado',
      actions: [for (final tm in _teams) IosGlassAction<Map<String, Object?>>(label: tm['name'] as String, value: tm, icon: CupertinoIcons.person_2_fill)],
    );
    if (mounted && selected != null) setState(() => (_crewId = selected['id'] as int, _crewName = selected['name'] as String));
  }

  /// QUÉ HACE: Construye el objeto `WorkSchedule` con la ventana horaria elegida.
  WorkSchedule? _buildSchedule() {
    final t = _selectedTemplate;
    if (t == null) return null;
    int? markStart = t.startMinute, markEnd = t.endMinute;
    if (_toleranceMode == 'Tolerancia ±30 min') {
      markStart = (t.startMinute - 30).clamp(0, 1439);
      markEnd = (t.endMinute + 30).clamp(0, 1439);
    } else if (_toleranceMode == 'Tolerancia ±60 min') {
      markStart = (t.startMinute - 60).clamp(0, 1439);
      markEnd = (t.endMinute + 60).clamp(0, 1439);
    } else if (_toleranceMode == 'Sin límite de hora') {
      markStart = null;
      markEnd = null;
    }
    return WorkSchedule(t.dailyMinutes, t.deductLunch, shiftName: t.name, startMinute: t.startMinute, endMinute: t.endMinute, markStartMinute: markStart, markEndMinute: markEnd, weekdays: t.weekdays);
  }

  /// QUÉ HACE: Valida y guarda el nuevo colaborador y su geocerca en SQLite.
  Future<void> _save() async {
    if (_saving) return;
    if (_name.text.trim().isEmpty || _document.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa el nombre completo y número de cédula.');
      return;
    }
    setState(() => (_saving = true, _error = null));
    try {
      final schedule = _buildSchedule();
      if (_gpsLat != null && _gpsLng != null) {
        final zoneId = await ref.read(localAdminStoreProvider).saveZone({'name': 'Zona (${_name.text.trim().split(' ').first})', 'latitude': _gpsLat!, 'longitude': _gpsLng!, 'radius_m': 100.0});
        if (_crewId != null) {
          final db = await ref.read(localPhotoDatabaseProvider).database;
          await db.update('crews', {'zone_id': zoneId}, where: 'id=?', whereArgs: [_crewId]);
        }
      }
      await ref.read(localPhotoRepositoryProvider).addWorker(_name.text.trim(), _document.text.trim(), _job.text.trim(), crewId: _crewId, schedule: schedule, authorizationReference: 'Afiliación por supervisor en campo');
      if (!mounted) return;
      ref.invalidate(localWorkersProvider);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => (_error = e is FormatException ? e.message : e.toString(), _saving = false));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _document.dispose();
    _job.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: IosFloatingModal(
        title: 'Registrar en Cuadrilla',
        isSaving: _saving,
        errorMessage: _error,
        onSave: _save,
        child: WorkerDialogFields(nameCtrl: _name, docCtrl: _document, jobCtrl: _job, selectedTemplate: _selectedTemplate, toleranceMode: _toleranceMode, crewName: _crewName, gpsLat: _gpsLat, gpsLng: _gpsLng, locating: _locating, onPickSchedule: _pickSchedule, onPickTolerance: _pickTolerance, onPickCrew: _pickCrew, onCaptureGps: _captureGps),
      ),
    );
  }
}
