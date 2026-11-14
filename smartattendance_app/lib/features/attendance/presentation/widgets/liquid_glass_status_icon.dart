// ============================================================================
// ARCHIVO: liquid_glass_status_icon.dart
// QUÉ HACE: Dibuja el icono circular y su insignia de estado de marcación.
// CÓMO: Combina superficie, borde e insignias completada/bloqueada en un Stack.
// POR QUÉ: Separa la ornamentación de la interacción de LiquidGlassCard.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LiquidGlassStatusIcon extends StatelessWidget {
  const LiquidGlassStatusIcon({
    super.key,
    required this.icon,
    required this.isDone,
    required this.isActive,
    required this.isDark,
    required this.primary,
    required this.success,
  });

  final IconData icon;
  final bool isDone, isActive, isDark;
  final Color primary, success;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone && !isDark
                    ? success.withValues(alpha: isDark ? 0.20 : 0.14)
                    : isActive
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFF0F172A).withValues(alpha: 0.08))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFF0F172A).withValues(alpha: 0.05)),
                border: Border.all(
                  color: isDone && !isDark
                      ? success.withValues(alpha: 0.60)
                      : isActive
                          ? (isDark
                              ? Colors.white.withValues(alpha: 0.35)
                              : const Color(0xFF0F172A).withValues(alpha: 0.25))
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : context.cBorder.withValues(alpha: 0.60)),
                  width: 0.85,
                ),
              ),
              child: Icon(
                icon,
                size: 18.5,
                color: isDone
                    ? (isDark ? context.cTextPrimary : success)
                    : isActive
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : context.cTextSecondary.withValues(alpha: 0.55),
              ),
            ),
            if (isDone)
              _badge(
                color: isDark ? const Color(0xFF566579) : success,
                borderColor: isDark ? const Color(0xFF071224) : Colors.white,
                icon: Icons.check,
                iconSize: 9,
              )
            else if (!isActive)
              _badge(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                borderColor: isDark ? const Color(0xFF071224) : Colors.white,
                icon: CupertinoIcons.lock_fill,
                iconSize: 8,
              ),
          ],
        ),
      );

  Widget _badge({
    required Color color,
    required Color borderColor,
    required IconData icon,
    required double iconSize,
  }) =>
      Positioned(
        right: -1,
        bottom: -1,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Icon(icon, size: iconSize, color: Colors.white),
        ),
      );
}
