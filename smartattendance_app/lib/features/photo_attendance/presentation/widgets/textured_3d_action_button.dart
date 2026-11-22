// ============================================================================
// ARCHIVO: textured_3d_action_button.dart
// QUÉ HACE: Adaptador modular que delega en `AquaGlossButton` para los botones
//           principales de Equipos y Zonas con estética limpia Apple Aqua 2006.
// CÓMO FUNCIONA: Mantiene la firma compatible y elimina bordes dobles o sombras
//                pesadas, proyectando una versión más compacta y refinada.
// POR QUÉ: Evita duplicación de código y conserva compatibilidad (< 40 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/design_system/aqua_gloss_button.dart';

class Textured3DActionButton extends StatelessWidget {
  const Textured3DActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.topColor,
    required this.bottomColor,
    required this.depthColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color topColor;
  final Color bottomColor;
  final Color depthColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => AquaGlossButton(
        icon: icon,
        label: label,
        topColor: topColor,
        bottomColor: bottomColor,
        onPressed: onPressed,
      );
}
