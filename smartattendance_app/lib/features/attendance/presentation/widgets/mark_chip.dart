// ============================================================================
// ARCHIVO: mark_chip.dart
// QUÉ HACE: Tarjeta interactiva para cada uno de los 4 eventos de la jornada
//           (Entrada, Inicio de almuerzo, Regreso de almuerzo y Salida).
// CÓMO FUNCIONA: Utiliza `context.cBackground` y `context.cBorder` para una
//                integración cromática limpia con `DaySummaryCard`, destacando
//                con borde primario la siguiente marcación sugerida.
// POR QUÉ: Elimina colores cálidos ajenos a la paleta (`#242426`) y permite
//          marcar directamente con un toque (< 135 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class MarkChip extends StatelessWidget {
  final String label;
  final String hora;
  final Color color;
  final IconData icon;
  final bool active;
  final bool isNext;
  final VoidCallback? onTap;

  const MarkChip({
    super.key,
    required this.label,
    required this.hora,
    required this.color,
    required this.icon,
    required this.active,
    this.isNext = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isNext
        ? AppColors.primary.withValues(alpha: 0.8)
        : (active ? AppColors.success.withValues(alpha: 0.45) : context.cBorder.withValues(alpha: 0.5));

    final bgColor = isNext
        ? AppColors.primary.withValues(alpha: 0.10)
        : (active ? AppColors.success.withValues(alpha: 0.08) : context.cSurface.withValues(alpha: 0.45));

    final fgIconColor = active
        ? AppColors.systemGreen
        : (isNext ? AppColors.primary : context.cTextSecondary);

    final fgTextColor = active || isNext
        ? context.cTextPrimary
        : context.cTextSecondary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: isNext ? 1.2 : 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    active ? Icons.check_circle_rounded : icon,
                    size: 14,
                    color: fgIconColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isNext || active ? FontWeight.w600 : FontWeight.w500,
                        color: fgTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hora,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? context.cTextPrimary
                          : context.cTextSecondary,
                      fontFeatures: AppDesignTokens.tabularFigures,
                    ),
                  ),
                  Icon(
                    active
                        ? Icons.done_all_rounded
                        : Icons.chevron_right_rounded,
                    size: 14,
                    color: active
                        ? AppColors.systemGreen
                        : context.cTextSecondary.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
