// ============================================================================
// ARCHIVO: serviciudad_status_bar.dart
// QUÉ HACE: Muestra el estado de jornada ("Por iniciar" / "Tiempo registrado")
//           y la sede asignada con separadores limpios y textos sin errores.
// CÓMO FUNCIONA: Renderiza dos filas organizadas separadas por un divisor fino
//                de 0.6px, con tipografía recta de alto contraste (#0F172A).
// POR QUÉ: Claridad visual y espacio para el mapa miniatura (< 105 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ServiciudadStatusBar extends StatelessWidget {
  const ServiciudadStatusBar({
    super.key,
    required this.statusText,
    required this.workedTime,
    required this.zoneLabel,
    required this.bulletColor,
    required this.primary,
    required this.isDark,
    required this.onOpenMap,
  });

  final String statusText, workedTime, zoneLabel;
  final Color bulletColor, primary;
  final bool isDark;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final primaryTxt = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTxt =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final iconColor =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF00439C);
    final dividerColor =
        isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Row(
            children: [
              Icon(CupertinoIcons.stopwatch, size: 17, color: iconColor),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: primaryTxt,
                ),
              ),
              const Spacer(),
              Text(
                'Tiempo registrado: $workedTime',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: secondaryTxt,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 0.6, color: dividerColor),
        InkWell(
          onTap: onOpenMap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Row(
              children: [
                Icon(CupertinoIcons.location_solid, size: 17, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    zoneLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: primaryTxt,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 14,
                  color: secondaryTxt,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
