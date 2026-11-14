// ============================================================================
// ARCHIVO: zone_menu_anchor.dart
// QUÉ HACE: Botón de acción rápida "+ Nueva Zona" que abre `ZoneDialog` con
//           mapa interactivo, búsqueda de dirección física real y GPS actual.
// CÓMO FUNCIONA: Invoca `showDialog<bool>` con `ZoneDialog` y refresca la vista.
// POR QUÉ: Permite crear sitios de trabajo con dirección verificable (< 55 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../zone_dialog.dart';

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
  Widget build(BuildContext context) => TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: context.cTextPrimary,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        ),
        onPressed: () => _openDialog(context),
        icon: const Icon(CupertinoIcons.location, size: 19),
        label: const Text(
          '+ Nueva Zona',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
}
