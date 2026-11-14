// ============================================================================
// ARCHIVO: crew_menu_anchor.dart
// QUÉ HACE: Botón de acción rápida "+ Nuevo Equipo" que abre `CrewDialog`
//           con selección de puestos (Operador, Colaborador, Operario, etc.),
//           sitio de trabajo con dirección e integrantes del equipo.
// CÓMO FUNCIONA: Invoca `showDialog<bool>` con `CrewDialog` y refresca la vista.
// POR QUÉ: Garantiza que al crear un Nuevo Equipo estén disponibles todos los
//          puestos creados por el Administrador y el sitio con dirección (< 55 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../crew_dialog.dart';

class CrewMenuAnchor extends StatelessWidget {
  const CrewMenuAnchor({super.key, required this.zones, required this.onSaved});
  final List<Map<String, Object?>> zones;
  final VoidCallback onSaved;

  Future<void> _openDialog(BuildContext context) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CrewDialog(zones: zones),
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
        icon: const Icon(CupertinoIcons.person_2, size: 19),
        label: const Text(
          '+ Nuevo Equipo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
}
