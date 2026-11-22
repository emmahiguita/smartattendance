// ============================================================================
// ARCHIVO: crew_zone_validity_section.dart
// QUÉ HACE: Renderiza la sección "Sitio de Trabajo con Dirección y Vigencia"
//           dentro de `CrewDialog` (Detalle de Cuadrilla / Nuevo Equipo).
// CÓMO FUNCIONA: Muestra el selector de sede; si se elige una sede existente
//                expone su dirección física y radio con claridad, y si se elige
//                "+ Nuevo sitio con dirección…" despliega campos en línea.
// POR QUÉ: Vista de detalles limpia, contextual y profesional (< 165 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../../core/theme/app_theme.dart';

class CrewZoneValiditySection extends StatelessWidget {
  const CrewZoneValiditySection({
    super.key,
    required this.zones,
    required this.selectedZoneId,
    required this.newZoneSentinel,
    required this.newZoneNameController,
    required this.newZoneAddressController,
    required this.validFrom,
    required this.validUntil,
    required this.busy,
    required this.onZoneChanged,
    required this.onPickDate,
  });

  final List<Map<String, Object?>> zones;
  final int? selectedZoneId;
  final int newZoneSentinel;
  final TextEditingController newZoneNameController, newZoneAddressController;
  final String? validFrom, validUntil;
  final bool busy;
  final ValueChanged<int?> onZoneChanged;
  final ValueChanged<bool> onPickDate;

  Widget _dateRow(BuildContext context, String label, String? val, bool start) => InkWell(
        onTap: busy ? null : () => onPickDate(start),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(CupertinoIcons.calendar, size: 15, color: Color(0xFF007AFF)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: context.cTextPrimary)),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(val ?? 'Seleccionar', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF007AFF))),
              const SizedBox(width: 4),
              Icon(CupertinoIcons.chevron_forward, size: 13, color: context.cTextSecondary),
            ]),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final validSelection = selectedZoneId == newZoneSentinel || zones.any((z) => z['id'] == selectedZoneId) ? selectedZoneId : null;
    final selectedZone = zones.where((z) => z['id'] == validSelection).firstOrNull;
    final isCreatingNewZone = validSelection == newZoneSentinel;

    return IosFormGroup(
      header: 'Sitio de Trabajo con Dirección y Vigencia',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(children: [
            const Icon(CupertinoIcons.location_fill, size: 15.5, color: Color(0xFF007AFF)),
            const SizedBox(width: 8),
            SizedBox(
              width: 86,
              child: Text('Sitio / Sede', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: context.cTextPrimary)),
            ),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: validSelection,
                  isExpanded: true,
                  dropdownColor: context.isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.cTextPrimary),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Zona Libre (sin geocerca fija)')),
                    for (final z in zones)
                      DropdownMenuItem<int?>(
                        value: z['id'] as int,
                        child: Text(
                          (z['address'] as String?)?.isNotEmpty == true ? '${z['name']} · ${z['address']}' : z['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    DropdownMenuItem<int?>(
                      value: newZoneSentinel,
                      child: const Text('+ Crear nuevo sitio con dirección…',
                          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF007AFF))),
                    ),
                  ],
                  onChanged: busy ? null : onZoneChanged,
                ),
              ),
            ),
          ]),
        ),
        if (selectedZone != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(children: [
              Icon(CupertinoIcons.map_pin_ellipse, size: 15, color: context.cTextSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Dirección: ${(selectedZone['address'] as String?)?.trim().isNotEmpty == true ? selectedZone['address'] : 'Coordenadas GPS registradas'} · Radio ${selectedZone['radius_m'] ?? 100} m',
                  style: TextStyle(fontSize: 12.2, color: context.cTextSecondary),
                ),
              ),
            ]),
          ),
        if (isCreatingNewZone) ...[
          IosFormFieldRow(
              label: 'Nombre Sitio', placeholder: 'Ej. Planta Operativa Norte', controller: newZoneNameController, textCapitalization: TextCapitalization.words),
          IosFormFieldRow(
              label: 'Dirección Real', placeholder: 'Ej. Calle 25 # 20-30, Dosquebradas', controller: newZoneAddressController, textCapitalization: TextCapitalization.sentences),
        ],
        _dateRow(context, 'Vigencia desde', validFrom, true),
        _dateRow(context, 'Vigencia hasta', validUntil, false),
      ],
    );
  }
}
