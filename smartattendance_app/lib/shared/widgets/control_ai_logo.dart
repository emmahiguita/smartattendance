// lib/shared/widgets/control_ai_logo.dart
import 'package:flutter/material.dart';
import 'buen_tiempo_logo.dart';

/// ============================================================================
/// COMPONENTE COMPATIBLE: ControlAiLogo -> Redirige a BuenTiempoLogo
/// ============================================================================
/// QUÉ HACE:
/// Actúa como adaptador arquitectónico (Adapter Pattern) para mantener
/// compatibilidad con las pantallas existentes mientras proyecta la marca oficial
/// "BuenTiempo" (sol, reloj y checkmark).
///
/// CÓMO FUNCIONA:
/// Recibe los parámetros históricos (`size`, `isHorizontal`, `iconOnly`, etc.)
/// y los mapea directamente a [BuenTiempoLogo], asegurando que toda la aplicación
/// adopte la nueva identidad gráfica sin romper contratos previos.
///
/// POR QUÉ:
/// Cumple con el principio Open/Closed de SOLID: El sistema evoluciona a la nueva
/// marca "BuenTiempo" sin necesidad de modificar agresivamente llamadas en decenas de archivos.
///
/// PRINCIPIOS SOLID:
/// - S (Single Responsibility): Adaptar llamadas de marca previas a BuenTiempo.
/// - L (Liskov Substitution): Puede utilizarse en cualquier lugar donde se esperaba el logo anterior.
/// ============================================================================
class ControlAiLogo extends StatelessWidget {
  final double size;
  final bool isHorizontal;
  final bool showSubtitle;
  final Color? textColor;
  final bool iconOnly;

  const ControlAiLogo({
    super.key,
    this.size = 32,
    this.isHorizontal = true,
    this.showSubtitle = false,
    this.textColor,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return BuenTiempoLogo(
      size: size,
      isHorizontal: isHorizontal,
      showSubtitle: showSubtitle,
      iconOnly: iconOnly,
      iosSquircle: iconOnly,
    );
  }
}
