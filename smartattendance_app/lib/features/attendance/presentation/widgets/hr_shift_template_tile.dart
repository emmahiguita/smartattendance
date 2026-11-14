// ============================================================================
// ARCHIVO: hr_shift_template_tile.dart
// QUÉ HACE: Presenta cada plantilla de turno como fila compacta estilo iOS.
// CÓMO FUNCIONA: Muestra nombre, horario dual colombiano (24h y 12h AM/PM) y
//                días laborables con espaciado vertical reducido (8px).
// POR QUÉ: Evita divisores muy separados y facilita comparar turnos (< 55 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../photo_attendance/domain/shift_template.dart';

class HrShiftTemplateTile extends StatelessWidget {
  const HrShiftTemplateTile({
    super.key,
    required this.template,
    required this.onTap,
  });

  final ShiftTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.clock,
                color: context.cTextSecondary,
                size: 19,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.cTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${template.timeFormattedDual} · ${template.weekdaysSummary} (${template.durationFormatted})',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.cTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 14,
                color: context.cTextSecondary,
              ),
            ],
          ),
        ),
      );
}
