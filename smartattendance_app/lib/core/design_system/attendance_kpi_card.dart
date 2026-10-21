// lib/core/design_system/attendance_kpi_card.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'ios_glass_card.dart';

/// ============================================================================
/// COMPONENTE: AttendanceKpiCard (Estilo iOS Glass)
/// ============================================================================
/// QUÉ HACE:
/// Tarjeta de métrica con efecto Glassmorphism que visualiza indicadores reales
/// de asistencia (Empleados activos, En jornada, Sin entrada, Jornadas cerradas).
///
/// CÓMO FUNCIONA:
/// Utiliza [IosGlassCard] translúcida con desenfoque de fondo y borde hairline.
/// Al seleccionar una métrica, resalta con el color representativo y activa el
/// filtro correspondiente en el listado del personal.
///
/// POR QUÉ:
/// Cumple con las directrices Apple HIG: componentes transparentes, bordes sutiles,
/// cifras tabulares y cero saturación cromática.
/// ============================================================================
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? AppColors.primary;
    final effectiveIconBg = iconBackgroundColor ??
        effectiveIconColor.withValues(alpha: isDark ? 0.2 : 0.1);

    final activeBorder = Border.all(
      color: isSelected
          ? effectiveIconColor
          : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E5EA)),
      width: isSelected ? 1.5 : 0.5,
    );

    return IosGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      borderRadius: 14,
      border: activeBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: effectiveIconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 18),
              ),
              if (isSelected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: effectiveIconColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (isLoading)
            const SizedBox(
              height: 26,
              width: 40,
              child: Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (errorMessage != null)
            const Text(
              'Error',
              style: TextStyle(color: AppColors.systemRed, fontSize: 13, fontWeight: FontWeight.w600),
            )
          else
            Text(
              stringValue ?? (value != null ? '$value' : '0'),
              style: AppDesignTokens.metricValue(
                color: context.cTextPrimary,
                fontSize: 24,
              ),
            ),
          const SizedBox(height: 3),

          Text(
            title,
            style: TextStyle(
              color: context.cTextPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6C6C70),
              fontSize: 11,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
