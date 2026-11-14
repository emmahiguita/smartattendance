// ============================================================================
// ARCHIVO: consolidated_edit_admin_section.dart
// CAPA: Presentation / Consolidated / Widgets
// QUÉ HACE: Editor de Sede, Estado, Horas Extras, Colaborador y Justificación.
// CÓMO FUNCIONA: Desplegables accesibles, chips rápidos de horas y campo de motivo.
// POR QUÉ: Asegura auditoría con justificación obligatoria y trazabilidad < 195 líneas.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class ConsolidatedEditAdminSection extends StatelessWidget {
  const ConsolidatedEditAdminSection({
    super.key,
    required this.selectedZone,
    required this.selectedStatus,
    required this.availableZones,
    required this.extrasCtrl,
    required this.reasonCtrl,
    required this.onZoneChanged,
    required this.onStatusChanged,
    this.workers = const [],
    this.selectedWorkerId,
    this.onWorkerChanged,
  });

  final String selectedZone;
  final String selectedStatus;
  final List<String> availableZones;
  final TextEditingController extrasCtrl;
  final TextEditingController reasonCtrl;
  final ValueChanged<String> onZoneChanged;
  final ValueChanged<String> onStatusChanged;
  final List<Map<String, dynamic>> workers;
  final int? selectedWorkerId;
  final ValueChanged<int>? onWorkerChanged;

  void _addMinutes(int mins) {
    final current = int.tryParse(extrasCtrl.text.trim()) ?? 0;
    extrasCtrl.text = '${current + mins}';
  }

  /// QUÉ HACE: Construye los selectores de colaborador, sede, estado, extras y motivo.
  /// CÓMO: Usa `DropdownButton` con alto contraste y `CupertinoTextField` legible.
  /// POR QUÉ: Garantiza visibilidad en modo oscuro (`#000000`) y claro.
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (workers.isNotEmpty && onWorkerChanged != null) ...[
          Text('Colaborador asignado', style: _labelStyle(context)),
          const SizedBox(height: 4),
          _dropdownBox(
            context,
            child: DropdownButton<int>(
              value: workers.any((w) => w['id'] == selectedWorkerId)
                  ? selectedWorkerId
                  : (workers.first['id'] as int?),
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              items: workers.map((w) {
                final id = w['id'] as int;
                final name = w['name'] as String;
                final doc = w['document'] as String;
                return DropdownMenuItem(
                  value: id,
                  child: Text(
                    '$name (CC $doc)',
                    style: TextStyle(fontSize: 12.5, color: context.cTextPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onWorkerChanged!(val);
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text('Sede / Zona de trabajo', style: _labelStyle(context)),
        const SizedBox(height: 4),
        _dropdownBox(
          context,
          child: DropdownButton<String>(
            value: availableZones.contains(selectedZone) ? selectedZone : availableZones.firstOrNull,
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            items: availableZones
                .map(
                  (z) => DropdownMenuItem(
                    value: z,
                    child: Text(z, style: TextStyle(fontSize: 12.5, color: context.cTextPrimary)),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) onZoneChanged(val);
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estado Jornada', style: _labelStyle(context)),
                  const SizedBox(height: 4),
                  _dropdownBox(
                    context,
                    child: DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      items: [
                        DropdownMenuItem(value: 'Cerrada', child: Text('Cerrada', style: TextStyle(fontSize: 12.5, color: context.cTextPrimary))),
                        DropdownMenuItem(value: 'Abierta', child: Text('Abierta', style: TextStyle(fontSize: 12.5, color: context.cTextPrimary))),
                        DropdownMenuItem(value: 'Anulada', child: Text('Anulada', style: TextStyle(fontSize: 12.5, color: context.cTextPrimary))),
                      ],
                      onChanged: (val) {
                        if (val != null) onStatusChanged(val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('H. Extras aprobadas (min)', style: _labelStyle(context)),
                  const SizedBox(height: 4),
                  CupertinoTextField(
                    controller: extrasCtrl,
                    keyboardType: TextInputType.number,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    placeholder: 'Minutos',
                    placeholderStyle: TextStyle(fontSize: 12.5, color: context.cTextSecondary),
                    style: TextStyle(fontSize: 13, color: context.cTextPrimary),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141414) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.cBorder, width: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _quickChip(context, '+30m', () => _addMinutes(30)),
            const SizedBox(width: 6),
            _quickChip(context, '+1h (60m)', () => _addMinutes(60)),
            const SizedBox(width: 6),
            _quickChip(context, '+2h (120m)', () => _addMinutes(120)),
            const SizedBox(width: 6),
            _quickChip(context, '0 min', () => extrasCtrl.text = '0'),
          ],
        ),
        const SizedBox(height: 12),
        Text('Motivo de corrección / justificación *', style: _labelStyle(context)),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: reasonCtrl,
          maxLines: 2,
          padding: const EdgeInsets.all(10),
          placeholder: 'Ej: Ajuste de marcación autorizado por dirección...',
          placeholderStyle: TextStyle(fontSize: 12.5, color: context.cTextSecondary),
          style: TextStyle(fontSize: 13, color: context.cTextPrimary),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.cBorder, width: 0.6),
          ),
        ),
      ],
    );
  }

  TextStyle _labelStyle(BuildContext context) =>
      TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: context.cTextSecondary);

  Widget _dropdownBox(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF141414) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.cBorder, width: 0.6),
      ),
      child: DropdownButtonHideUnderline(child: child),
    );
  }

  Widget _quickChip(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: context.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: context.cBorder, width: 0.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: context.cTextPrimary)),
      ),
    );
  }
}
