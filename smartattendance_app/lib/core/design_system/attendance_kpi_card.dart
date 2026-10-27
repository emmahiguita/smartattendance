// ============================================================================
// ARCHIVO: attendance_kpi_card.dart
// QUÉ HACE: Tarjeta ejecutiva de indicador operacional (KPI) con estética
//           sobria libre de cajas multicolor saturadas ("vibe coding").
// CÓMO FUNCIONA: Muestra etiqueta concisa sin truncamiento, subtexto neutro,
//                indicador discreto de estado (6px) y cifra tabular alineada.
// POR QUÉ: Garantiza lectura inmediata en cuadrícula 2x2 móvil sin cortar
//          palabras con "..." y mantiene sobriedad visual (< 130 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'ios_glass_card.dart';

class AttendanceKpiCard extends StatelessWidget {
  const AttendanceKpiCard({
    super.key,
    required this.title,
    this.value,
    this.stringValue,
    required this.subtitle,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.isLoading = false,
    this.errorMessage,
    this.isSelected = false,
    this.onTap,
  });

  final String title;
  final int? value;
  final String? stringValue;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool isLoading;
  final String? errorMessage;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dotColor = iconColor ?? AppColors.primary;

    final activeBorder = Border.all(
      color: isSelected ? AppColors.primary : context.cBorder,
      width: isSelected ? 1.4 : 0.8,
    );

    return IosGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: 12,
      border: activeBorder,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: context.cTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.cTextSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isLoading)
            const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 1.8),
            )
          else if (errorMessage != null)
            Icon(Icons.error_outline, color: context.cTextSecondary, size: 16)
          else
            Text(
              stringValue ?? '${value ?? 0}',
              style: AppDesignTokens.metricValue(
                color: isSelected ? AppColors.primary : context.cTextPrimary,
                fontSize: 20,
              ),
            ),
        ],
      ),
    );
  }
}
