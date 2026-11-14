// ============================================================================
// ARCHIVO: worker_dialog_actions.dart
// QUÉ HACE: Coordina selección de puesto (Operador, Colaborador, Operario, etc.),
//           creación de puestos por el Administrador, asignación de equipo y
//           sitio de trabajo con dirección real en SQLite.
// CÓMO FUNCIONA: Carga puestos personalizados, cuadrillas con sus zonas/direcciones
//                y geocodifica direcciones escritas antes de persistir la ficha.
// POR QUÉ: Garantiza que siempre permita asignar puesto, equipo y sitio con
//          dirección sin errores (< 195 líneas).
// ============================================================================
part of 'worker_dialog.dart';

abstract class _WorkerDialogActions extends ConsumerState<WorkerDialog> {
  final _password = TextEditingController(), _confirmation = TextEditingController();
  final _name = TextEditingController(), _document = TextEditingController();
  final _job = TextEditingController(text: 'Operador'), _address = TextEditingController();
  List<Map<String, Object?>> _teams = [];
  List<Map<String, Object?>> _zones = [];
  List<ShiftTemplate> _templates = [];
  List<String> _customPositions = [];
  int? _crewId;
  String? _crewName;
  ShiftTemplate? _selectedTemplate;
  String _toleranceMode = 'Turno exacto';
  double? _gpsLat, _gpsLng;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final store = ref.read(localAdminStoreProvider);
      await store.ensureDefaultData();
      final teams = await store.crewsWithZones();
      final zones = await store.rows('work_zones');
      final templates = await store.shiftTemplates();
      final customPos = await store.customJobPositions();
      final actor = ref.read(localActorProvider);
      final workers = await store.rows('workers');
      final myWorker = workers.where((w) => (w['document'] as String?)?.trim() == actor.document.trim()).firstOrNull;
      final myCrewId = myWorker?['crew_id'] as int?;
      if (!mounted) return;
      setState(() {
        _teams = teams;
        _zones = zones;
        _templates = templates;
        _customPositions = customPos;
        if (teams.isNotEmpty) {
          final supCrews = teams.where((t) => (t['supervisor_document'] as String?)?.trim() == actor.document.trim());
          final defaultCrew = actor.isStrictAdmin
              ? teams.first
              : (teams.where((t) => t['id'] == myCrewId).firstOrNull ?? supCrews.lastOrNull ?? teams.first);
          _applySelectedCrew(defaultCrew);
        }
        if (templates.isNotEmpty) _selectedTemplate ??= templates.first;
      });
    } catch (_) {}
  }

  void _applySelectedCrew(Map<String, Object?> crew) {
    _crewId = crew['id'] as int?;
    final zName = crew['zone_name'] as String?;
    final zAddr = crew['zone_address'] as String?;
    _crewName = zName != null && zName.isNotEmpty ? '${crew['name']} · $zName' : crew['name'] as String?;
    if (_address.text.trim().isEmpty && zAddr != null && zAddr.isNotEmpty) {
      _address.text = zAddr;
      _gpsLat = (crew['zone_lat'] as num?)?.toDouble();
      _gpsLng = (crew['zone_lng'] as num?)?.toDouble();
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
      title: 'Puesto y Nivel de Acceso',
      subtitle: 'Selecciona Operador, Colaborador, Operario u otro puesto',
      actions: [
        for (final pos in positions)
          IosGlassAction<String>(
            label: pos,
            subtitle: AppRoles.descriptionFor(pos),
            value: pos,
            icon: AppRoles.isStrictAdmin(pos)
                ? CupertinoIcons.shield_fill
                : (AppRoles.isSupervisorOrManager(pos) ? CupertinoIcons.person_2_fill : CupertinoIcons.person_fill),
          ),
        if (isStrictAdmin)
          const IosGlassAction<String>(
            label: '+ Crear nuevo puesto laboral…',
            subtitle: 'Exclusivo del Administrador (queda guardado en el sistema)',
            value: '__create_new__',
            icon: CupertinoIcons.add_circled_solid,
          ),
      ],
    );
    if (!mounted || selected == null) return;
    if (selected == '__create_new__') {
      final ctrl = TextEditingController();
      final created = await showCupertinoDialog<String>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Crear Nuevo Puesto'),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: CupertinoTextField(controller: ctrl, placeholder: 'Ej. Operador de Red, Fontanero…', textCapitalization: TextCapitalization.words, autofocus: true),
          ),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Crear')),
          ],
        ),
      );
      ctrl.dispose();
      if (created != null && created.isNotEmpty && mounted) {
        final updated = await ref.read(localAdminStoreProvider).addCustomJobPosition(created);
        if (mounted) setState(() => (_customPositions = updated, _job.text = created));
      }
      return;
    }
    setState(() => _job.text = selected);
  }

  Future<void> _pickSchedule() async {
    final selected = await showIosGlassFloatingMenu<ShiftTemplate>(
      context: context,
      title: 'Horario y Turno Asignado',
      subtitle: 'Selecciona la jornada laboral predefinida',
      actions: [for (final t in _templates) IosGlassAction<ShiftTemplate>(label: t.name, subtitle: t.timeFormattedDual, value: t, icon: CupertinoIcons.clock_fill)],
    );
    if (mounted && selected != null) setState(() => _selectedTemplate = selected);
  }

  Future<void> _pickTolerance() async {
    const opts = ['Turno exacto', 'Tolerancia ±30 min', 'Tolerancia ±60 min', 'Sin límite de hora'];
    final selected = await showIosGlassFloatingMenu<String>(
      context: context,
      title: 'Rango de Marcación Permitido',
      subtitle: 'Ventana de flexibilidad horaria autorizada',
      actions: [for (final opt in opts) IosGlassAction<String>(label: opt, value: opt, icon: CupertinoIcons.timer_fill)],
    );
    if (mounted && selected != null) setState(() => _toleranceMode = selected);
  }

  Future<void> _pickCrew() async {
    final selected = await showIosGlassFloatingMenu<Map<String, Object?>>(
      context: context,
      title: 'Asignar a Equipo y Sitio',
      subtitle: 'Selecciona la cuadrilla o crea una nueva con dirección',
      actions: [
        for (final tm in _teams)
          IosGlassAction<Map<String, Object?>>(
            label: tm['name'] as String,
            subtitle: tm['zone_name'] != null ? 'Sitio: ${tm['zone_name']} (${tm['zone_address'] ?? 'Sin dirección'})' : 'Sin sitio fijo asignado',
            value: tm,
            icon: CupertinoIcons.person_2_fill,
          ),
        const IosGlassAction<Map<String, Object?>>(
          label: '+ Crear Nuevo Equipo con Puestos y Sitio…',
          subtitle: 'Abre el configurador de Nuevo Equipo',
          value: {'id': -1},
          icon: CupertinoIcons.add_circled_solid,
        ),
      ],
    );
    if (!mounted || selected == null) return;
    if (selected['id'] == -1) {
      final created = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) => CrewDialog(zones: _zones));
      if (created == true && mounted) await _loadMetadata();
      return;
    }
    setState(() => _applySelectedCrew(selected));
  }

  WorkSchedule? _buildSchedule() {
    final t = _selectedTemplate;
    if (t == null) return null;
    final int? tolerance = switch (_toleranceMode) {
      'Tolerancia ±30 min' => 30,
      'Tolerancia ±60 min' => 60,
      'Sin límite de hora' => null,
      _ => 0,
    };
    return t.toScheduleWithTolerance(tolerance);
  }

  Future<void> _save() async {
    if (_saving) return;
    final doc = _document.text.trim(), name = _name.text.trim(), role = _job.text.trim();
    if (name.isEmpty || doc.isEmpty) return setState(() => _error = 'Ingresa el nombre completo y número de cédula.');
    final actor = ref.read(localActorProvider);
    if (!actor.isStrictAdmin && (AppRoles.isStrictAdmin(role) || AppRoles.isSupervisorOrManager(role))) {
      return setState(() => _error = 'Como supervisor/encargado solo puedes afiliar colaboradores, operadores y operarios.');
    }
    if (_password.text != _confirmation.text) return setState(() => _error = 'Las contraseñas no coinciden.');
    setState(() => (_saving = true, _error = null));
    try {
      final addr = _address.text.trim();
      double? lat = _gpsLat, lng = _gpsLng;
      if (addr.isNotEmpty && (lat == null || lng == null)) {
        final geocoded = await const TraccarService().geocodeAddress(addr);
        lat = geocoded?.latitude ?? 4.8333;
        lng = geocoded?.longitude ?? -75.6833;
      }
      int? targetCrewId = _crewId;
      if (targetCrewId == null && addr.isNotEmpty && actor.isStrictAdmin) {
        final now = DateTime.now();
        targetCrewId = await ref.read(localAdminStoreProvider).saveCrew({
          'name': 'Equipo Operativo General',
          'supervisor_document': actor.document.trim().isNotEmpty ? actor.document.trim() : doc,
          'driver_document': '',
          'zone_id': null,
          'valid_from': now.toIso8601String().split('T').first,
          'valid_until': now.add(const Duration(days: 365)).toIso8601String().split('T').first,
        });
      }
      await ref.read(localPhotoRepositoryProvider).addWorker(
        name, doc, role, crewId: targetCrewId, schedule: _buildSchedule(), password: _password.text,
        site: (lat == null || lng == null || addr.isEmpty || targetCrewId == null)
            ? null
            : WorkerSite(name: 'Sitio ${name.split(' ').first} ($role)', address: addr, latitude: lat, longitude: lng),
        authorizationReference: actor.isStrictAdmin ? 'Afiliación por Administrador' : 'Afiliación por Supervisor de Cuadrilla',
      );
      if (!mounted) return;
      ref.invalidate(localWorkersProvider);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => (_error = e is FormatException ? e.message : e.toString(), _saving = false));
    }
  }

  @override
  void dispose() {
    _name.dispose(); _document.dispose(); _job.dispose(); _address.dispose();
    _password.dispose(); _confirmation.dispose();
    super.dispose();
  }
}
