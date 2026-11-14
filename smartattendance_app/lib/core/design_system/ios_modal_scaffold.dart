// ============================================================================
// ARCHIVO: ios_modal_scaffold.dart
// QUÉ HACE: Formularios modales planos estilo iOS con transición elástica suave,
//           texto legible y divisores finos de 0.5px sin tarjetas anidadas.
// CÓMO FUNCIONA: Conserva la API (`IosFloatingModal`, `IosFormGroup`,
//                `IosFormFieldRow`) e integra transición de entrada iOS (escala
//                0.96 -> 1.0 + desplazamiento sutil) y `AnimatedSize` fluido.
// POR QUÉ: Unifica las sub-ventanas (Geocercas, Equipos, Asignación) con física
//          Apple iOS profesional sin alterar íconos ni diseño (< 200 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class IosFloatingModal extends StatelessWidget {
  const IosFloatingModal({
    super.key,
    required this.title,
    required this.onSave,
    required this.child,
    this.saveLabel = 'Guardar',
    this.isSaving = false,
    this.errorMessage,
  });

  final String title, saveLabel;
  final bool isSaving;
  final String? errorMessage;
  final VoidCallback onSave;
  final Widget child;

  // QUÉ HACE: Construye el diálogo modal con transición de entrada estilo iOS.
  // CÓMO: Respeta MediaQuery.disableAnimationsOf y aplica TweenAnimationBuilder.
  // POR QUÉ: Aporta fluidez nativa de iOS a cualquier showDialog existente.
  @override
  Widget build(BuildContext context) {
    final disableAnim = MediaQuery.disableAnimationsOf(context);
    final dialog = Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.cBorder, width: 0.5),
      ),
      backgroundColor: context.isDark ? Colors.black : Colors.white,
      insetPadding: const EdgeInsets.all(14),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Cancelar',
                    onPressed: isSaving
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context);
                          },
                    icon: const Icon(Icons.close, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.cTextPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            onSave();
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            saveLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: context.cTextPrimary,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: context.cBorder),
            AnimatedSize(
              duration: disableAnim ? Duration.zero : const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: errorMessage == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(
                        errorMessage!,
                        semanticsLabel: 'Error: $errorMessage',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.cTextPrimary,
                        ),
                      ),
                    ),
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: AnimatedSize(
                  duration: disableAnim ? Duration.zero : const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (disableAnim) return dialog;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, value, content) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1.0 - value) * 14.0),
          child: Transform.scale(
            scale: 0.96 + (0.04 * value),
            child: content,
          ),
        ),
      ),
      child: dialog,
    );
  }
}

class IosFormGroup extends StatelessWidget {
  const IosFormGroup({super.key, this.header, required this.children});
  final String? header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 5),
              child: Text(
                header!.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: context.cTextSecondary,
                ),
              ),
            ),
          Divider(height: 1, thickness: 0.5, color: context.cBorder),
          for (final child in children) ...[
            child,
            Divider(height: 1, thickness: 0.5, color: context.cBorder),
          ],
        ],
      );
}

class IosFormFieldRow extends StatelessWidget {
  const IosFormFieldRow({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.prefixIcon,
    this.trailing,
  });

  final String label, placeholder;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                textCapitalization: textCapitalization,
                onChanged: onChanged,
                style: TextStyle(fontSize: 14, color: context.cTextPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  labelText: label,
                  hintText: placeholder,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  prefixIcon: prefixIcon == null
                      ? null
                      : Icon(prefixIcon, size: 18, color: context.cTextSecondary),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      );
}
