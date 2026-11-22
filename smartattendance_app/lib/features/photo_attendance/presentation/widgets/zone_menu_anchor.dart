// ============================================================================
// ARCHIVO: zone_menu_anchor.dart
// QUÉ HACE: Botón de acción rápida "+ Nueva Zona" que abre `ZoneDialog` con
//           mapa interactivo, búsqueda de dirección física real y GPS actual.
// CÓMO FUNCIONA: Invoca `showDialog<bool>` con `ZoneDialog` y refresca la vista.
// POR QUÉ: Permite crear sitios de trabajo con dirección verificable (< 55 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../zone_dialog.dart';
import 'textured_3d_action_button.dart';

class ZoneMenuAnchor extends StatelessWidget {
  const ZoneMenuAnchor({super.key, required this.onSaved});
  final VoidCallback onSaved;

  Future<void> _openDialog(BuildContext context) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ZoneDialog(),
    );
    if (saved == true) onSaved();
  }

  @override
  Widget build(BuildContext context) => Textured3DActionButton(
        icon: CupertinoIcons.location_solid,
        label: '+ Nueva Zona',
        topColor: const Color(0xFF0EA5A8),
        bottomColor: const Color(0xFF007782),
        depthColor: const Color(0xFF004F57),
        onPressed: () => _openDialog(context),
      );
}
