// ============================================================================
// ARCHIVO: map_zone_picker_sheet.dart
// QUÉ HACE: Modal inferior estilo iOS para seleccionar y enfocar entre las sedes
//           y geocercas operativas reales registradas en SQLite.
// CÓMO FUNCIONA: Muestra listado ordenado con estado activo y callback de selección.
// POR QUÉ: Extrae la lógica de selección de sedes cumpliendo SRP (< 85 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/work_zone.dart';

void showMapZonePickerSheet({
  required BuildContext context,
  required List<WorkZone> zones,
  required WorkZone? activeZone,
  required ValueChanged<WorkZone> onZoneSelected,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.cBackground,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SEDES Y GEOCERCAS (${zones.length})',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.cTextSecondary),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Icon(CupertinoIcons.xmark_circle_fill,
                      size: 20, color: context.cTextSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: zones.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final z = zones[i];
                  final isSel = z.id == activeZone?.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      CupertinoIcons.building_2_fill,
                      color: isSel
                          ? const Color(0xFF007AFF)
                          : context.cTextSecondary,
                    ),
                    title: Text(z.name,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSel ? FontWeight.w700 : FontWeight.w500)),
                    subtitle: Text(
                        '${z.address ?? 'Dosquebradas'} • Radio ${z.radius.round()} m',
                        style: const TextStyle(fontSize: 12)),
                    trailing: isSel
                        ? const Icon(CupertinoIcons.checkmark_alt,
                            color: Color(0xFF007AFF), size: 18)
                        : null,
                    onTap: () {
                      onZoneSelected(z);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
