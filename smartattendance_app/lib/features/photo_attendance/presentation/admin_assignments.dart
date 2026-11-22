// ============================================================================
// ARCHIVO: admin_assignments.dart
// QUÉ HACE: Lista los sitios de trabajo y equipos guardados con alta, edición
//           y vista de detalles profesional con iconografía azul iOS (#007AFF).
// CÓMO FUNCIONA: Presenta botones de acción superiores, resuelve el nombre real
//                del supervisor desde `localWorkersProvider` y renderiza filas
//                abiertas iOS con divisores finos de 0.5px y tipografía nítida.
// POR QUÉ: Aprovecha el espacio vertical con textos claros y legibles (< 185 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../domain/photo_record.dart';
import 'crew_dialog.dart';
import 'local_providers.dart';
import 'widgets/crew_menu_anchor.dart';
import 'widgets/zone_menu_anchor.dart';
import 'zone_dialog.dart';

class AdminAssignments extends ConsumerStatefulWidget {
  const AdminAssignments({super.key});
  @override
  ConsumerState<AdminAssignments> createState() => _AdminAssignmentsState();
}

class _AdminAssignmentsState extends ConsumerState<AdminAssignments> {
  static const Color _iosBlue = Color(0xFF007AFF);
  late Future<List<List<Map<String, Object?>>>> _data;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final store = ref.read(localAdminStoreProvider);
    _data = Future.wait([store.rows('work_zones'), store.crewsWithZones()]);
  }

  Future<void> _edit(Widget dialog) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => dialog,
    );
    if (saved == true && mounted) {
      ref.invalidate(localWorkersProvider);
      setState(_refresh);
    }
  }

  String _crewSubtitle(Map<String, Object?> c, List<LocalWorker> workers) {
    final doc = (c['supervisor_document'] as String? ?? '').trim();
    final sup = workers.where((w) => w.document.trim() == doc).firstOrNull;
    final supLabel = sup != null ? '${sup.name} (C.C. $doc)' : 'C.C. $doc';
    final zName = (c['zone_name'] as String?)?.trim() ?? '';
    final zAddr = (c['zone_address'] as String?)?.trim() ?? '';
    final siteLabel = zName.isEmpty ? 'Sin sitio asignado' : (zAddr.isNotEmpty ? '$zName · $zAddr' : zName);
    return 'Supervisor: $supLabel\nSitio: $siteLabel';
  }

  Widget _section(String title, List<Widget> rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Text(title,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.45, color: context.cTextSecondary)),
          ),
          Divider(height: 1, thickness: 0.5, color: context.cBorder),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Sin registros configurados', style: TextStyle(fontSize: 13, color: context.cTextSecondary)),
            ),
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            Divider(height: 1, thickness: 0.5, indent: i < rows.length - 1 ? 36 : 0, color: context.cBorder),
          ],
        ],
      );

  Widget _row(IconData icon, String title, String subtitle, VoidCallback onTap, {Color iconColor = _iosBlue}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
          child: Row(children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.11), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 17.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, letterSpacing: -0.15, color: context.cTextPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12.5, height: 1.3, color: context.cTextSecondary)),
              ]),
            ),
            const SizedBox(width: 6),
            Icon(CupertinoIcons.chevron_forward, size: 15, color: _iosBlue.withValues(alpha: 0.75)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final workers = ref.watch(localWorkersProvider).valueOrNull ?? const [];
    return FutureBuilder(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TextButton(onPressed: () => setState(_refresh), child: const Text('Reintentar cargar sitios y equipos'));
        }
        if (!snapshot.hasData) {
          return const Padding(padding: EdgeInsets.all(20), child: Center(child: CupertinoActivityIndicator()));
        }
        final zones = snapshot.data![0], crews = snapshot.data![1];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 6),
            child: Row(children: [
              Expanded(child: ZoneMenuAnchor(onSaved: () => setState(_refresh))),
              const SizedBox(width: 10),
              Expanded(child: CrewMenuAnchor(zones: zones, onSaved: () => setState(_refresh))),
            ]),
          ),
          _section('SITIOS DE TRABAJO (${zones.length})', [
            for (final z in zones)
              _row(
                CupertinoIcons.location,
                z['name'] as String,
                '${(z['address'] as String?)?.trim().isNotEmpty == true ? z['address'] : 'Ubicación GPS registrada'} · Radio: ${z['radius_m']} m',
                () => _edit(ZoneDialog(zone: z)),
              ),
          ]),
          _section('EQUIPOS Y CUADRILLAS (${crews.length})', [
            for (final c in crews)
              _row(CupertinoIcons.person_2_fill, c['name'] as String, _crewSubtitle(c, workers), () => _edit(CrewDialog(crew: c, zones: zones))),
          ]),
        ]);
      },
    );
  }
}
