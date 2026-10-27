// lib/core/design_system/ios_floating_glass_sheet.dart
// ============================================================================
// ARCHIVO: ios_floating_glass_sheet.dart
// CAPA: Core / Design System (Sábana Flotante Translúcida Estilo Apple iOS Glass)
// ----------------------------------------------------------------------------
// QUÉ HACE:
// Presenta un diálogo modal suspendido con desenfoque gaussiano de 30px (BackdropFilter),
// bordes cristalinos translúcidos y esquinas redondeadas 28dp, flotando libremente
// en el centro de la pantalla sin anclarse nunca al borde inferior.
//
// CÓMO FUNCIONA:
// - Detecta orientación (Vertical vs Horizontal / Landscape) de forma reactiva.
// - En Horizontal: Amplía el ancho a `min(width * 0.90, 820)` para dar espacio a
//   tablas complejas y evitar recortes o cuellos de botella visuales.
// - En Vertical: Centra la sábana con ancho ergonómico para uso con una mano.
//
// POR QUÉ:
// Directriz estricta del usuario: "DEBE SER ESTILO IOS TRASPARENTE Y SABANA FLOTANTE
// GLASSES LOS MENU NO ABREN NUNCA DESDE ABAJO" y "corrige modo horizontal" (< 160 líneas).
// ============================================================================

import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
export 'ios_glass_menu.dart';

/// Despliega una sábana modal flotante con estética translúcida iOS Liquid Glass.
Future<T?> showIosFloatingGlassSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  String? subtitle,
  double maxHeightFactor = 0.78,
  bool showCloseButton = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black.withValues(alpha: context.isDark ? 0.55 : 0.35),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, anim, secAnim) {
      final size = MediaQuery.of(ctx).size;
      final isLandscape = size.width > size.height;

      // Adaptación ergonómica horizontal vs vertical para evitar cortes
      final dialogMaxWidth = isLandscape ? min(size.width * 0.90, 820.0) : min(size.width * 0.94, 480.0);
      final dialogMaxHeight = isLandscape ? size.height * 0.92 : size.height * maxHeightFactor;

      return Material(
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 24 : 18,
              vertical: isLandscape ? 12 : 24,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: dialogMaxHeight,
                    maxWidth: dialogMaxWidth,
                  ),
                  decoration: BoxDecoration(
                    color: ctx.cSurface.withValues(alpha: ctx.isDark ? 0.72 : 0.86),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: ctx.isDark ? 0.22 : 0.65),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: ctx.isDark ? 0.45 : 0.16),
                        blurRadius: 38,
                        spreadRadius: 2,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 38,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: ctx.cBorder.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      if (title != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 14, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: isLandscape ? 16 : 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.4,
                                        color: ctx.cTextPrimary,
                                      ),
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          fontSize: isLandscape ? 11 : 12,
                                          color: ctx.cTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (showCloseButton)
                                GestureDetector(
                                  onTap: () => Navigator.pop(ctx),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: ctx.cBorder.withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(CupertinoIcons.xmark, size: 14, color: ctx.cTextPrimary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Divider(height: 1, thickness: 0.7, color: ctx.cBorder.withValues(alpha: 0.5)),
                      ],
                      Flexible(child: child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, secAnim, pageChild) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: pageChild,
        ),
      );
    },
  );
}
