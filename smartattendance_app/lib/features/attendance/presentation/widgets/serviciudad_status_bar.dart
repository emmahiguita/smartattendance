// ============================================================================
// ARCHIVO: serviciudad_status_bar.dart
// QUÉ HACE: Muestra estado de jornada, tiempo registrado y sede en filas iOS.
// CÓMO FUNCIONA: Compacta el espaciado vertical (8px) y usa divisor fino (0.5px)
//                entre el resumen de tiempo y el acceso a la ubicación asignada.
// POR QUÉ: Evita espacios vacíos amplios entre divisores (< 65 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

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
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Wrap(
              spacing: 18,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: context.cTextPrimary,
                  ),
                ),
                Text(
                  'Tiempo registrado: $workedTime',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: context.cTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: context.cBorder),
          InkWell(
            onTap: onOpenMap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 19,
                    color: context.cTextSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      zoneLabel,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: context.cTextPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 15,
                    color: context.cTextSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}
