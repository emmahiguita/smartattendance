// ============================================================================
// ARCHIVO: ios_floating_glass_sheet.dart
// QUÉ HACE: Presenta selectores y sábanas modales con superficie Liquid Glass
//           profesional: BackdropFilter 24px + borde 0.8px + transición iOS.
// CÓMO FUNCIONA: showGeneralDialog con curva easeOutCubic + ClipRRect +
//                BackdropFilter rodea el Dialog para el efecto glass real.
// POR QUÉ: Unifica estética iOS Liquid Glass en todos los modales < 120 líneas.
// ============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
export 'ios_glass_menu.dart';

/// QUÉ HACE: Despliega una hoja modal con superficie Liquid Glass real (blur 24px).
/// CÓMO: BackdropFilter + BoxDecoration borde 0.8px blanco/15% opacidad.
/// POR QUÉ: Estética iOS Apple sin alterar el contenido interno.
Future<T?> showIosFloatingGlassSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  String? subtitle,
  double maxHeightFactor = 0.78,
  bool showCloseButton = true,
}) {
  final disableAnim = MediaQuery.disableAnimationsOf(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black.withValues(alpha: 0.50),
    transitionDuration:
        disableAnim ? Duration.zero : const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, __) {
      final size = MediaQuery.sizeOf(ctx);
      final theme = Theme.of(ctx);
      final radius = BorderRadius.circular(20);

      // QUÉ HACE: Superficie Liquid Glass real con BackdropFilter 24px.
      // CÓMO: ClipRRect contiene el BackdropFilter, luego DecoratedBox
      //       aplica el tint semitransparente y el borde ultra-fino.
      return Dialog(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Tint oscuro noche profundo en dark, blanco translúcido en light
                color: isDark
                    ? const Color(0xFF07101E).withValues(alpha: 0.80)
                    : Colors.white.withValues(alpha: 0.82),
                borderRadius: radius,
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.13 : 0.55),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 640,
                  maxHeight: (size.height -
                          MediaQuery.viewInsetsOf(ctx).bottom) *
                      maxHeightFactor,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(fontWeight: FontWeight.w700)),
                                  if (subtitle != null)
                                    Text(subtitle,
                                        style: theme.textTheme.bodyMedium),
                                ],
                              ),
                            ),
                            if (showCloseButton)
                              IconButton(
                                tooltip: 'Cerrar',
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  Navigator.pop(ctx);
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                          ],
                        ),
                      ),
                      Divider(
                          height: 1,
                          thickness: 0.6,
                          color: Colors.white.withValues(alpha: 0.12)),
                    ],
                    Flexible(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, secAnim, dialogChild) {
      if (disableAnim) return dialogChild;
      final curved = CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
            child: dialogChild,
          ),
        ),
      );
    },
  );
}
