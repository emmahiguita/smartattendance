// ============================================================================
// ARCHIVO: admin_assignments.dart
// QUÉ HACE: Lista los sitios de trabajo y equipos guardados con alta y edición.
// CÓMO FUNCIONA: Presenta botones de acción superiores y filas abiertas iOS
//                con espaciado compacto (8px) y divisores finos de 0.5px.
// POR QUÉ: Aprovecha el espacio vertical sin tarjetas ni separaciones grandes.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
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

  Widget _section(String title, List<Widget> rows) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: context.cTextSecondary,
              ),
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: context.cBorder),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Sin registros',
                style: TextStyle(fontSize: 13, color: context.cTextSecondary),
              ),
            ),
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            Divider(
              height: 1,
              thickness: 0.5,
              indent: i < rows.length - 1 ? 32 : 0,
              color: context.cBorder,
            ),
          ],
        ],
      );

  Widget _row(
          IconData icon, String title, String subtitle, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: context.cTextSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: context.cTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.cTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 15,
                color: context.cTextSecondary,
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return TextButton(
              onPressed: () => setState(_refresh),
              child: const Text('Reintentar cargar sitios y equipos'),
            );
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CupertinoActivityIndicator()),
            );
          }
          final zones = snapshot.data![0], crews = snapshot.data![1];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  ZoneMenuAnchor(onSaved: () => setState(_refresh)),
                  CrewMenuAnchor(
                      zones: zones, onSaved: () => setState(_refresh)),
                ],
              ),
              _section('SITIOS DE TRABAJO (${zones.length})', [
                for (final z in zones)
                  _row(
                    CupertinoIcons.location,
                    z['name'] as String,
                    '${z['address'] ?? ''} · Radio: ${z['radius_m']} m',
                    () => _edit(ZoneDialog(zone: z)),
                  ),
              ]),
              _section('EQUIPOS (${crews.length})', [
                for (final c in crews)
                  _row(
                    CupertinoIcons.person_2,
                    c['name'] as String,
                    'Supervisor: ${c['supervisor_document']} · ${c['zone_name'] != null ? '${c['zone_name']}${(c['zone_address'] as String?)?.isNotEmpty == true ? ' (${c['zone_address']})' : ''}' : 'Sin sitio asignado'}',
                    () => _edit(CrewDialog(crew: c, zones: zones)),
                  ),
              ]),
            ],
          );
        },
      );
}
