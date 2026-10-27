// ============================================================================
// ARCHIVO: hr_shift_templates_strip.dart
// QUÉ HACE: Catálogo de Plantillas de Turnos Oficiales (`ShiftTemplate`) en
//           formato Apple iOS Inset Grouped con menú de acción nativo Cupertino.
// CÓMO FUNCIONA: Muestra cada turno oficial en una lista agrupada con bordes
//                finos (0.5px) y al tocar despliega un `CupertinoActionSheet`
//                para editar o eliminar el turno sin menús flotantes desordenados.
// POR QUÉ: Sustituye el carrusel con `PopupMenuButton` por un bloque iOS limpio
//          y cumple SRP (< 150 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/photo_record.dart';
import '../../../photo_attendance/domain/shift_template.dart';

class HrShiftTemplatesStrip extends StatelessWidget {
  final List<LocalWorker> workers;
  final List<ShiftTemplate> templates;
  final VoidCallback onCreateShift;
  final ValueChanged<ShiftTemplate> onEditShift, onDeleteShift;

  const HrShiftTemplatesStrip({
    super.key,
    required this.workers,
    required this.templates,
    required this.onCreateShift,
    required this.onEditShift,
    required this.onDeleteShift,
  });

  void _openTemplateActions(BuildContext context, ShiftTemplate t) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(t.name),
        message: Text('${t.timeFormatted} · ${t.weekdaysSummary}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              onEditShift(t);
            },
            child: const Text('Editar horario del turno'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              onDeleteShift(t);
            },
            child: const Text('Eliminar plantilla'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 4, bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PLANTILLAS DE HORARIO (${templates.length})',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                  color: context.cTextSecondary,
                ),
              ),
              GestureDetector(
                onTap: onCreateShift,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.add_circled_solid,
                        size: 15, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Nuevo Turno',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.cSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.cBorder, width: 0.5),
          ),
          child: templates.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Sin plantillas de turno registradas.',
                    style:
                        TextStyle(fontSize: 12.5, color: context.cTextSecondary),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < templates.length; i++) ...[
                      InkWell(
                        onTap: () =>
                            _openTemplateActions(context, templates[i]),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Icon(CupertinoIcons.clock_fill,
                                    size: 15, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      templates[i].name,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: context.cTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${templates[i].weekdaysSummary} · ${templates[i].durationFormatted}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: context.cTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                templates[i].timeFormatted,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(CupertinoIcons.chevron_forward,
                                  size: 14, color: context.cTextSecondary),
                            ],
                          ),
                        ),
                      ),
                      if (i < templates.length - 1)
                        Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 52,
                            color: context.cBorder),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
