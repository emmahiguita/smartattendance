// ============================================================================
// ARCHIVO: crew_zone_validity_section.dart
// QUÉ HACE: Renderiza la sección "Sitio de Trabajo con Dirección y Vigencia"
//           dentro de `CrewDialog`, permitiendo elegir una sede existente o
//           crear en línea un "+ Nuevo sitio con dirección…".
// CÓMO FUNCIONA: Usa `IosFormGroup` con selector desplegable y campos de texto
//                condicionales (`Nombre Sitio`, `Dirección`) más fechas.
// POR QUÉ: Mantiene `crew_dialog.dart` por debajo de las 200 líneas (Regla 1).
// ============================================================================

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
  final TextEditingController newZoneNameController;
  final TextEditingController newZoneAddressController;
  final String? validFrom;
  final String? validUntil;
  final bool busy;
  final ValueChanged<int?> onZoneChanged;
  final ValueChanged<bool> onPickDate;

  /// QUÉ HACE: Construye una fila interactiva para seleccionar fecha de vigencia.
  /// CÓMO: Ejecuta `onPickDate(start)` al tocar la fila si no está guardando.
  /// POR QUÉ: Evita repetir el layout de fecha inicio y fecha fin.
  Widget _dateRow(BuildContext context, String label, String? val, bool start) {
    return InkWell(
      onTap: busy ? null : () => onPickDate(start),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.cTextPrimary,
              ),
            ),
            Text(
              val ?? 'Seleccionar',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: context.cTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validSelection = selectedZoneId == newZoneSentinel ||
            zones.any((z) => z['id'] == selectedZoneId)
        ? selectedZoneId
        : null;

    return IosFormGroup(
      header: 'Sitio de Trabajo con Dirección y Vigencia',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  'Sitio / Sede',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.cTextPrimary,
                  ),
                ),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: validSelection,
                    isExpanded: true,
                    dropdownColor:
                        context.isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    style: TextStyle(fontSize: 12.5, color: context.cTextPrimary),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Libre (sin restricción)'),
                      ),
                      for (final z in zones)
                        DropdownMenuItem<int?>(
                          value: z['id'] as int,
                          child: Text(
                            (z['address'] as String?)?.isNotEmpty == true
                                ? '${z['name']} · ${z['address']}'
                                : z['name'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      DropdownMenuItem<int?>(
                        value: newZoneSentinel,
                        child: const Text(
                          '+ Nuevo sitio con dirección…',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                    onChanged: busy ? null : onZoneChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        IosFormFieldRow(
          label: 'Nombre Sitio',
          placeholder: 'Ej. Planta Acueducto',
          controller: newZoneNameController,
          textCapitalization: TextCapitalization.words,
        ),
        IosFormFieldRow(
          label: 'Dirección',
          placeholder: 'Ej. Calle 25 # 20-30, Dosquebradas',
          controller: newZoneAddressController,
          textCapitalization: TextCapitalization.sentences,
        ),
        _dateRow(context, 'Válido desde', validFrom, true),
        _dateRow(context, 'Válido hasta', validUntil, false),
      ],
    );
  }
}
