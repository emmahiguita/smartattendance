// ============================================================================
// ARCHIVO: aqua_gloss_button.dart
// QUÉ HACE: Botón de acción profesional estilo iOS con gradiente continuo
//           suave, borde cristalino único de 0.7px y respuesta táctil fluida.
// CÓMO FUNCIONA: Elimina cortes horizontales abruptos a mitad del botón y
//                aplica `AnimatedScale` + `AnimatedOpacity` con curva iOS.
// POR QUÉ: Garantiza botones limpios ("+ Nueva Zona", "+ Nuevo Equipo",
//          "Guardar", "Agregar", "Ruta") sin artefactos visuales (< 140 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AquaGlossButton extends StatefulWidget {
  const AquaGlossButton({
    super.key,
    required this.label,
    required this.topColor,
    required this.bottomColor,
    required this.onPressed,
    this.icon,
    this.compact = false,
    this.isLoading = false,
  });

  final String label;
  final IconData? icon;
  final Color topColor;
  final Color bottomColor;
  final VoidCallback? onPressed;
  final bool compact;
  final bool isLoading;

  @override
  State<AquaGlossButton> createState() => _AquaGlossButtonState();
}

class _AquaGlossButtonState extends State<AquaGlossButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final radius = widget.compact ? 9.0 : 10.5;
    final vPad = widget.compact ? 5.0 : 7.0;
    final hPad = widget.compact ? 10.0 : 11.0;
    final fontSize = widget.compact ? 11.5 : 12.0;
    final iconSize = widget.compact ? 13.0 : 14.0;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? widget.onPressed : null,
        onTapDown: enabled
            ? (_) {
                HapticFeedback.selectionClick();
                _setPressed(true);
              }
            : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: enabled ? (_pressed ? 0.88 : 1.0) : 0.50,
            duration: const Duration(milliseconds: 120),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(widget.topColor, Colors.white, 0.10)!,
                    widget.topColor,
                    widget.bottomColor,
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 0.7,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.bottomColor.withValues(alpha: 0.22),
                    offset: const Offset(0, 3),
                    blurRadius: 8,
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize:
                    widget.compact ? MainAxisSize.min : MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading)
                    const CupertinoActivityIndicator(
                      radius: 7.5,
                      color: Colors.white,
                    )
                  else ...[
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: iconSize, color: Colors.white),
                      const SizedBox(width: 5.5),
                    ],
                    Flexible(
                      fit: widget.compact ? FlexFit.loose : FlexFit.tight,
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        textAlign:
                            widget.compact ? TextAlign.start : TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
