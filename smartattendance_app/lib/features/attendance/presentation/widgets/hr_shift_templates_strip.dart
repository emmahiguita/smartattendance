// ============================================================================
// ARCHIVO: hr_shift_templates_strip.dart
// QUÉ HACE: Lista plantillas de turno y permite crear, editar y eliminar horarios.
// CÓMO FUNCIONA: Presenta filas compactas separadas por divisores finos (0.5px)
//                con acciones en hoja modal inferior estilo iOS.
// POR QUÉ: Mantiene el catálogo de turnos visible y compacto (< 90 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/shift_template.dart';
import 'hr_shift_template_tile.dart';

class HrShiftTemplatesStrip extends StatelessWidget {
  const HrShiftTemplatesStrip({
    super.key,
    required this.workers,
    required this.templates,
    required this.onCreateShift,
    required this.onEditShift,
    required this.onDeleteShift,
  });

  final List<LocalWorker> workers;
  final List<ShiftTemplate> templates;
  final VoidCallback onCreateShift;
  final ValueChanged<ShiftTemplate> onEditShift, onDeleteShift;

  void _actions(BuildContext context, ShiftTemplate template) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                dense: true,
                title: Text(template.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(template.timeFormattedDual),
              ),
              const Divider(height: 1, thickness: 0.5),
              ListTile(
                dense: true,
                leading: const Icon(CupertinoIcons.pencil, size: 19),
                title: const Text('Editar horario del turno'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onEditShift(template);
                },
              ),
              const Divider(height: 1, thickness: 0.5),
              ListTile(
                dense: true,
                leading: const Icon(CupertinoIcons.trash, size: 19),
                title: const Text('Eliminar plantilla'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onDeleteShift(template);
                },
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'PLANTILLAS DE HORARIO (${templates.length})',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: context.cTextSecondary,
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: context.cTextPrimary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: onCreateShift,
                icon: const Icon(CupertinoIcons.add, size: 17),
                label: const Text(
                  'Nuevo Turno',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Divider(height: 1, thickness: 0.5, color: context.cBorder),
          if (templates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Sin plantillas de turno registradas.',
                style: TextStyle(fontSize: 13, color: context.cTextSecondary),
              ),
            ),
          for (var i = 0; i < templates.length; i++) ...[
            HrShiftTemplateTile(
              template: templates[i],
              onTap: () => _actions(context, templates[i]),
            ),
            Divider(
              height: 1,
              thickness: 0.5,
              indent: i < templates.length - 1 ? 30 : 0,
              color: context.cBorder,
            ),
          ],
        ],
      );
}
