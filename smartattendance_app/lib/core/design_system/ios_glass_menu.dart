// lib/core/design_system/ios_glass_menu.dart
// ============================================================================
// ARCHIVO: ios_glass_menu.dart
// CAPA: Core / Design System (Menús y Acciones Flotantes iOS Liquid Glass)
// ----------------------------------------------------------------------------
// QUÉ HACE:
// Despliega menús contextuales flotantes con estética iOS Liquid Glass real:
// BackdropFilter 20px + borde 0.8px + divisores ultra-finos 0.5px.
//
// CÓMO FUNCIONA:
// - [IosGlassAction]: Modelo genérico (label, value, icon, destructive).
// - [showIosGlassFloatingMenu]: Llama a `showIosFloatingGlassSheet` con
//   lista de tarjetas ClipRRect + BackdropFilter y botón Cancelar glass.
//
// POR QUÉ: SRP — desacopla menús de acción del modal base < 150 líneas.
// ============================================================================

import 'dart:ui';
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

/// Muestra un menú de opciones Liquid Glass con desenfoque gaussiano real.
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
          // QUÉ HACE: Lista de acciones con glass real (blur + borde 0.8px).
          // CÓMO: ClipRRect + BackdropFilter rodean el Container de acciones.
          // POR QUÉ: Aplica Liquid Glass dentro del modal ya blureado.
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: context.cSurface.withValues(
                      alpha: context.isDark ? 0.45 : 0.65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(
                        alpha: context.isDark ? 0.12 : 0.50),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.white.withValues(
                              alpha: context.isDark ? 0.10 : 0.30),
                        ),
                      _MenuActionTile<T>(action: actions[i]),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // QUÉ HACE: Botón Cancelar con superficie glass propia.
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: context.cSurface.withValues(
                    alpha: context.isDark ? 0.50 : 0.80),
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
    final textColor = action.isDestructive
        ? CupertinoColors.destructiveRed
        : context.cTextPrimary;
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
                      style: TextStyle(
                          fontSize: 11.5, color: context.cTextSecondary),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: context.cTextSecondary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
