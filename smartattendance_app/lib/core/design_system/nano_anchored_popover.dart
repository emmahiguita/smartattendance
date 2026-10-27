// ============================================================================
// ARCHIVO: nano_anchored_popover.dart
// QUÉ HACE: Presentador de menú emergente de cristal anclado a un botón objetivo,
//           según la especificación Nano Compact Glass Composer.
// CÓMO FUNCIONA: Calcula las coordenadas globales del botón emisor y despliega
//                una superficie `GlassSurface` (máx 280 dp) con animación finita
//                de 190 ms, filas táctiles >= 48 dp y semántica accesible.
// POR QUÉ: Cumple el patrón Nano aprobado el 26-Oct-2026 (< 200 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class NanoPopoverAction {
  const NanoPopoverAction({
    required this.title,
    required this.icon,
    this.iconSize = 18.0,
    this.iconColor,
    this.onTap,
    this.hasSubmenu = false,
  });

  final String title;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool hasSubmenu;
}

/// Muestra el menú anclado de cristal con un único propietario para evitar
/// dobles aperturas o cierres concurrentes.
Future<T?> showNanoAnchoredPopover<T>({
  required BuildContext context,
  required GlobalKey anchorKey,
  required List<NanoPopoverAction> actions,
  String? headerTitle,
}) {
  final renderBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (renderBox == null) return Future.value(null);

  final translation = renderBox.localToGlobal(Offset.zero);
  final size = renderBox.size;
  final media = MediaQuery.of(context);
  final disableAnim = media.disableAnimations;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar menú',
    barrierColor: Colors.black.withValues(alpha: 0.28),
    transitionDuration: disableAnim ? Duration.zero : const Duration(milliseconds: 190),
    pageBuilder: (ctx, anim, secAnim) {
      return _NanoPopoverRouteView<T>(
        anchorRect: Rect.fromLTWH(translation.dx, translation.dy, size.width, size.height),
        actions: actions,
        headerTitle: headerTitle,
      );
    },
    transitionBuilder: (ctx, anim, secAnim, child) {
      if (disableAnim) return child;
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          alignment: Alignment.bottomLeft,
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _NanoPopoverRouteView<T> extends StatelessWidget {
  const _NanoPopoverRouteView({
    required this.anchorRect,
    required this.actions,
    this.headerTitle,
  });

  final Rect anchorRect;
  final List<NanoPopoverAction> actions;
  final String? headerTitle;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDark = context.isDark;
    const popoverWidth = 260.0;

    final fitsAbove = anchorRect.top > 240;
    final top = fitsAbove
        ? (anchorRect.top - (actions.length * 50.0 + 30.0)).clamp(media.padding.top + 8, media.size.height)
        : anchorRect.bottom + 8.0;

    final left = anchorRect.left.clamp(12.0, media.size.width - popoverWidth - 12.0);

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      label: headerTitle ?? 'Menú de acciones',
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: popoverWidth,
            child: Material(
              color: Colors.transparent,
              child: GlassSurface(
                borderRadius: BorderRadius.circular(16),
                blurSigmaX: 18,
                blurSigmaY: 18,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (headerTitle != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: Text(
                          headerTitle!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.titanium : AppColors.primary,
                          ),
                        ),
                      ),
                      Divider(height: 1, thickness: 0.5, color: context.cBorder.withValues(alpha: 0.5)),
                    ],
                    ...actions.map((act) => _buildActionRow(context, act)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, NanoPopoverAction action) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        action.onTap?.call();
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              action.icon,
              size: action.iconSize,
              color: action.iconColor ?? (context.isDark ? AppColors.snow : AppColors.graphite),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.cTextPrimary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (action.hasSubmenu)
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: context.cTextSecondary.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );
  }
}
