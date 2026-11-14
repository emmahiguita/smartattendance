// ============================================================================
// ARCHIVO: crew_positions_section.dart
// QUÉ HACE: Sección interactiva para seleccionar los puestos laborales aplicados
//           a un equipo (`Operador`, `Colaborador`, `Operario`, `Promotor`, etc.)
//           y permitir al Administrador crear nuevos puestos en SQLite.
// CÓMO FUNCIONA: Muestra chips seleccionables de alto contraste y un botón
//                exclusivo para el Administrador (`+ Crear puesto`) que persiste
//                en `LocalAdminStore.addCustomJobPosition`.
// POR QUÉ: Cumple el requisito de que el Administrador cree los puestos y que
//          en Nuevo Equipo se puedan seleccionar y aplicar (< 175 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/design_system/ios_modal_scaffold.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class CrewPositionsSection extends StatelessWidget {
  const CrewPositionsSection({
    super.key,
    required this.allPositions,
    required this.selectedPositions,
    required this.isStrictAdmin,
    required this.onTogglePosition,
    required this.onCreatePosition,
  });

  final List<String> allPositions;
  final Set<String> selectedPositions;
  final bool isStrictAdmin;
  final ValueChanged<String> onTogglePosition;
  final ValueChanged<String> onCreatePosition;

  /// QUÉ HACE: Abre un cuadro de diálogo iOS para que el Administrador cree un puesto.
  Future<void> _promptNewPosition(BuildContext context) async {
    final ctrl = TextEditingController();
    final created = await showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Crear Nuevo Puesto'),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: ctrl,
            placeholder: 'Ej. Operador de Planta, Fontanero…',
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Crear Puesto'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (created != null && created.isNotEmpty) {
      onCreatePosition(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return IosFormGroup(
      header: 'Puestos Aplicados al Equipo',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isStrictAdmin
                          ? 'Selecciona los puestos del equipo o crea uno nuevo:'
                          : 'Selecciona los puestos asignables en este equipo:',
                      style: TextStyle(fontSize: 11.5, color: context.cTextSecondary),
                    ),
                  ),
                  if (isStrictAdmin)
                    InkWell(
                      onTap: () => _promptNewPosition(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.add_circled_solid, size: 14, color: context.cTextPrimary),
                            const SizedBox(width: 4),
                            Text(
                              'Crear puesto',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: context.cTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final pos in allPositions)
                    _PositionChip(
                      label: pos,
                      selected: selectedPositions.contains(pos),
                      isDark: isDark,
                      onTap: () => onTogglePosition(pos),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PositionChip extends StatelessWidget {
  const _PositionChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? Colors.white : const Color(0xFF0F172A);
    final activeFg = isDark ? Colors.black : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? activeBg : context.cBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? activeBg : context.cBorder,
            width: 0.7,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              size: 13,
              color: selected ? (isDark ? AppColors.success : Colors.white) : context.cTextSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? activeFg : context.cTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
