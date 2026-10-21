// lib/features/history/presentation/widgets/weekday_label.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// ============================================================================
/// COMPONENTE: WeekdayLabel (Etiqueta de Día de la Semana iOS Style)
/// ============================================================================
/// QUÉ HACE:
/// Muestra las iniciales de los días de la semana (L, M, M, J, V, S, D)
/// con ancho fijo y tipografía secundaria uniforme.
///
/// CÓMO FUNCIONA:
/// Centra el texto en un contenedor de 32px para coincidir con la grilla de 7 columnas.
///
/// POR QUÉ:
/// Principio de Responsabilidad Única (SRP - SOLID):
/// Desacoplado para mantener [IosCalendarMonthGrid] por debajo de 200 líneas.
/// ============================================================================
class WeekdayLabel extends StatelessWidget {
  final String text;
  const WeekdayLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: context.cTextSecondary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
