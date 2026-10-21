import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_providers.dart';
import 'zone_dialog.dart';
import 'crew_dialog.dart';

/// Adapta Configuración: grupos colapsables evitan cambiar el Inicio original.
/// Cargar una vez y refrescar al guardar evita consultas en cada reconstrucción.
class AdminAssignments extends ConsumerStatefulWidget {
  const AdminAssignments({super.key});
  @override
  ConsumerState<AdminAssignments> createState() => _AdminAssignmentsState();
}

class _AdminAssignmentsState extends ConsumerState<AdminAssignments> {
  late Future<List<List<Map<String, Object?>>>> _data;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final store = ref.read(localAdminStoreProvider);
    _data = Future.wait([store.rows('work_zones'), store.rows('crews')]);
  }

  Future<void> _edit(Widget dialog) async {
    final saved = await showDialog<bool>(
        context: context, barrierDismissible: false, builder: (_) => dialog);
    if (saved == true && mounted) setState(_refresh);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TextButton(
              onPressed: () => setState(_refresh),
              child: const Text('Reintentar cargar equipos y geocercas'));
        }
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final zones = snapshot.data![0], crews = snapshot.data![1];
        return Column(children: [
          ExpansionTile(
              title: const Text('Geocercas (opcional)'),
              leading: const Icon(Icons.map_outlined),
              children: [
                for (final z in zones)
                  ListTile(
                      title: Text(z['name'] as String),
                      subtitle: Text('Radio ${z['radius_m']} m'),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _edit(ZoneDialog(zone: z))),
                TextButton.icon(
                    onPressed: () => _edit(const ZoneDialog()),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear zona desde mapa')),
              ]),
          ExpansionTile(
              title: const Text('Equipos y responsables'),
              leading: const Icon(Icons.groups_outlined),
              children: [
                for (final c in crews)
                  ListTile(
                      title: Text(c['name'] as String),
                      subtitle:
                          Text('${c['valid_from']} a ${c['valid_until']}'),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _edit(CrewDialog(crew: c, zones: zones))),
                TextButton.icon(
                    onPressed: zones.isEmpty
                        ? null
                        : () => _edit(CrewDialog(zones: zones)),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear equipo')),
              ]),
        ]);
      });
}
