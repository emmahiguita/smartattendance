// lib/features/attendance/presentation/widgets/mark_chip.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// ============================================================================
/// COMPONENTE: MarkChip (Card Super Miniatura Estilo iOS)
/// ============================================================================
/// QUÉ HACE:
/// Tarjeta miniatura interactiva para los 4 eventos esenciales de la jornada:
/// Entrada, Inicio de Almuerzo, Regreso de Almuerzo y Salida.
///
/// CÓMO FUNCIONA:
/// 1. Si está registrada: muestra la hora real con checkmark verde.
/// 2. Si está pendiente: muestra '--:--' con borde fino táctil.
/// Tocar la tarjeta abre directamente la captura biométrica sin pasos intermedios.
///
/// POR QUÉ:
/// Elimina textos redundantes como "Marcar" cumpliendo estrictamente con Apple HIG (< 200 líneas).
/// ============================================================================
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isNext
        ? AppColors.primary.withValues(alpha: 0.6)
        : (active
            ? AppColors.systemGreen.withValues(alpha: 0.4)
            : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)));

    final bgColor = isNext
        ? AppColors.primary.withValues(alpha: 0.05)
        : (active
            ? AppColors.systemGreen.withValues(alpha: 0.05)
            : (isDark ? const Color(0xFF242426) : const Color(0xFFF9F9FB)));

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: isNext ? 1.0 : 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    active ? Icons.check_circle_rounded : icon,
                    size: 14,
                    color: active ? AppColors.systemGreen : (isNext ? AppColors.primary : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70))),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isNext || active ? FontWeight.w600 : FontWeight.w500,
                          color: active
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isNext ? AppColors.primary : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70))),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      hora,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? context.cTextPrimary : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93)),
                        fontFeatures: AppDesignTokens.tabularFigures,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    active ? Icons.done_all_rounded : Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: active ? AppColors.systemGreen : (isDark ? const Color(0xFF48484A) : const Color(0xFFC7C7CC)),
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
