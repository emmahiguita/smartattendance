// lib/core/design_system/ios_glass_menu.dart
// ============================================================================
// ARCHIVO: ios_glass_menu.dart
// CAPA: Core / Design System (Menús y Acciones Flotantes iOS Glass)
// ----------------------------------------------------------------------------
// QUÉ HACE:
// Despliega menús contextuales flotantes de selección única con estética
// iOS Liquid Glass (filas translúcidas con chevron, iconos y opción destructiva).
//
// CÓMO FUNCIONA:
// - [IosGlassAction]: Modelo genérico para cada opción (label, value, icon, destructive).
// - [showIosGlassFloatingMenu]: Función auxiliar que invoca `showIosFloatingGlassSheet`
//   presentando una lista de tarjetas translúcidas con separadores finos.
//
// POR QUÉ:
// Aplica el Principio de Responsabilidad Única (SRP) de SOLID:
// Desacopla la lógica de menús de acción de la sábana modal base, manteniendo
// archivos compactos (< 130 líneas) y facilitando el mantenimiento.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ios_floating_glass_sheet.dart';

/// Modelo descriptivo de cada opción en un menú flotante iOS Glass.
class IosGlassAction<T> {
  const IosGlassAction({
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.isDestructive = false,
  });

  final String label;
  final T value;
  final String? subtitle;
  final IconData? icon;
  final bool isDestructive;
}

/// Muestra un menú de opciones estilizado flotando con desenfoque gaussiano.
Future<T?> showIosGlassFloatingMenu<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<IosGlassAction<T>> actions,
}) {
  return showIosFloatingGlassSheet<T>(
    context: context,
    title: title,
    subtitle: subtitle,
    maxHeightFactor: 0.65,
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: context.cSurface.withValues(alpha: context.isDark ? 0.55 : 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.cBorder.withValues(alpha: 0.6), width: 0.8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < actions.length; i++) ...[
                    if (i > 0) Divider(height: 1, thickness: 0.6, color: context.cBorder.withValues(alpha: 0.5)),
                    _MenuActionTile<T>(action: actions[i]),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: context.cSurface.withValues(alpha: context.isDark ? 0.6 : 0.85),
            borderRadius: BorderRadius.circular(16),
            onPressed: () => Navigator.pop(context),
            child: Center(
              child: Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.cTextPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Elemento de lista para cada acción en el menú flotante.
class _MenuActionTile<T> extends StatelessWidget {
  const _MenuActionTile({required this.action});
  final IosGlassAction<T> action;

  @override
  Widget build(BuildContext context) {
    final textColor = action.isDestructive ? CupertinoColors.destructiveRed : context.cTextPrimary;
    return InkWell(
      onTap: () => Navigator.pop(context, action.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            if (action.icon != null) ...[
              Icon(action.icon, size: 20, color: textColor),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (action.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle!,
                      style: TextStyle(fontSize: 11.5, color: context.cTextSecondary),
                    ),
                  ],
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 14, color: context.cTextSecondary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
