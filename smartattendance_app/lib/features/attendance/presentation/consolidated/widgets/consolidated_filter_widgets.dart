// ============================================================================
// ARCHIVO: consolidated_filter_widgets.dart
// CAPA: Presentation / Consolidated / Widgets
// QUÉ HACE: Cápsulas interactivas y chips de filtro estilo Apple iOS con
//           contraste claro sobre fondo negro (#000000).
// CÓMO FUNCIONA: Renderiza botones con bordes de 0.5px y texto legible.
// POR QUÉ: Evita textos oscuros invisibles en modo oscuro (< 115 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final activeBg = isDark ? Colors.white : const Color(0xFF0F172A);
    final activeFg = isDark ? Colors.black : Colors.white;

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      minimumSize: const Size(34, 34),
      color: isActive
          ? activeBg
          : (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFF1F5F9)),
      borderRadius: BorderRadius.circular(9),
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isActive ? activeFg : context.cTextPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isActive ? activeFg : context.cTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class FilterCapsule extends StatelessWidget {
  const FilterCapsule({
    super.key,
    required this.label,
    required this.isActive,
    required this.icon,
  });

  final String label;
  final bool isActive;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark
                ? Colors.white.withValues(alpha: 0.14)
                : const Color(0xFFE2E8F0))
            : (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? context.cTextPrimary : context.cBorder,
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isActive ? context.cTextPrimary : context.cTextSecondary,
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 125),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.cTextPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            CupertinoIcons.chevron_down,
            size: 10,
            color: context.cTextSecondary,
          ),
        ],
      ),
    );
  }
}
