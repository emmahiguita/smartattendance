// ============================================================================
// ARCHIVO: admin_assignments.dart
// QUÉ HACE: Panel ejecutivo de administración de Geocercas GPS (`work_zones`)
//           y Equipos de Trabajo (`crews`) en formato Apple iOS Inset Grouped.
// CÓMO FUNCIONA: Consulta `LocalAdminStore` y presenta dos secciones agrupadas
//                con cabeceras en mayúsculas, divisores finos (0.5px) y
//                apertura directa de las ventanas flotantes `ZoneDialog` y `CrewDialog`.
// POR QUÉ: Reduce el archivo de 244 a < 165 líneas cumpliendo SRP y estética iOS.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'crew_dialog.dart';
import 'local_providers.dart';
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

  Widget _buildIosGroup({
    required BuildContext context,
    required String header,
    required String actionLabel,
    required VoidCallback? onAction,
    required String emptyText,
    required List<Widget> rows,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.only(left: 12, right: 4, bottom: 6),
        child: Row(children: [
          Expanded(
            child: Text(
              header,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: context.cTextSecondary),
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onAction,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(CupertinoIcons.add_circled_solid, size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ]),
            ),
          ],
        ]),
      ),
      Container(
        decoration: BoxDecoration(color: context.cSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.cBorder, width: 0.5)),
        child: rows.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text(emptyText, style: TextStyle(fontSize: 12.5, color: context.cTextSecondary)),
              )
            : Column(children: [
                for (var i = 0; i < rows.length; i++) ...[
                  rows[i],
                  if (i < rows.length - 1) Divider(height: 1, thickness: 0.5, indent: 52, color: context.cBorder),
                ],
              ]),
      ),
    ]);
  }

  Widget _buildRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(7)),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.cTextPrimary)),
              Text(subtitle, style: TextStyle(fontSize: 11.5, color: context.cTextSecondary)),
            ]),
          ),
          const Text('Editar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(width: 4),
          Icon(CupertinoIcons.chevron_forward, size: 14, color: context.cTextSecondary),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return TextButton(onPressed: () => setState(_refresh), child: const Text('Reintentar cargar geocercas y equipos'));
          }
          if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CupertinoActivityIndicator()));
          final zones = snapshot.data![0], crews = snapshot.data![1];
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildIosGroup(
              context: context,
              header: 'GEOCERCAS GPS (${zones.length})',
              actionLabel: 'Nueva Zona',
              onAction: () => _edit(const ZoneDialog()),
              emptyText: 'Sin geocercas GPS configuradas. Toca "+ Nueva Zona" para delimitar un perímetro en el mapa.',
              rows: [
                for (final z in zones)
                  _buildRow(
                    context: context,
                    icon: CupertinoIcons.location_fill,
                    iconColor: AppColors.primary,
                    title: z['name'] as String,
                    subtitle: '${(z['address'] as String?)?.isNotEmpty == true ? "${z['address']} · " : ""}Radio: ${z['radius_m']} m · (${(z['latitude'] as num).toStringAsFixed(4)}, ${(z['longitude'] as num).toStringAsFixed(4)})',
                    onTap: () => _edit(ZoneDialog(zone: z)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildIosGroup(
              context: context,
              header: 'EQUIPOS Y CUADRILLAS (${crews.length})',
              actionLabel: 'Nuevo Equipo',
              onAction: () => _edit(CrewDialog(zones: zones)),
              emptyText: 'Sin cuadrillas registradas. Toca "+ Nuevo Equipo" para asignar supervisor y geocerca.',
              rows: [
                for (final c in crews)
                  _buildRow(
                    context: context,
                    icon: CupertinoIcons.person_2_fill,
                    iconColor: AppColors.systemGreen,
                    title: c['name'] as String,
                    subtitle: 'Supervisor: ${c['supervisor_document']} · ${c['zone_name'] != null ? "${c['zone_name']}${(c['zone_address'] as String?)?.isNotEmpty == true ? ' (${c['zone_address']})' : ''}" : "Sin zona fija"}',
                    onTap: () => _edit(CrewDialog(crew: c, zones: zones)),
                  ),
              ],
            ),
          ]);
        },
      );
}
