// ============================================================================
// ARCHIVO: consolidated_metrics_grid.dart
// CAPA: Presentation / Consolidated / Widgets
// QUÉ HACE: Barra compacta de indicadores clave del Consolidado (Jornadas,
//           Personal, Entradas y Horas Extras) con divisores iOS de 0.5px.
// CÓMO FUNCIONA: Reemplaza las 4 tarjetas pesadas por una franja plana con
//                separadores verticales y horizontales de alta precisión.
// POR QUÉ: Aprovecha el espacio vertical y mantiene el estilo iOS (< 120 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../controllers/consolidated_attendance_state.dart';

class ConsolidatedMetricsGrid extends StatelessWidget {
  const ConsolidatedMetricsGrid({super.key, required this.state});

  final ConsolidatedAttendanceState state;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Jornadas', '${state.totalJornadas}'),
      ('Personal', '${state.personalUnico}'),
      ('Entradas', '${state.totalEntradas}'),
      ('Extras', state.totalExtrasFormatted),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      VerticalDivider(
                        width: 1,
                        thickness: 0.5,
                        color: context.cBorder,
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              items[i].$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                                color: context.cTextPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              items[i].$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: context.cTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: context.cBorder),
        ],
      ),
    );
  }
}
