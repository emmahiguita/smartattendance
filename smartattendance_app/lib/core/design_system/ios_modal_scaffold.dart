// ============================================================================
// ARCHIVO: ios_modal_scaffold.dart
// QUÉ HACE: Sábana flotante y formularios estilo Apple iOS 18 Liquid Glass
//           100% transparentes en modo oscuro.
// CÓMO FUNCIONA: `IosFloatingModal` e `IosFormGroup` aplican `BackdropFilter`
//                con desenfoque gaussiano real y bordes especulares de cristal.
// POR QUÉ: Cumple la directiva de modo oscuro 100% iOS transparente profesional
//          y mantiene el archivo estrictamente < 180 líneas.
// ============================================================================

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class IosFloatingModal extends StatelessWidget {
  final String title, saveLabel;
  final bool isSaving;
  final String? errorMessage;
  final VoidCallback onSave;
  final Widget child;

  const IosFloatingModal({
    super.key,
    required this.title,
    required this.onSave,
    required this.child,
    this.saveLabel = 'Guardar',
    this.isSaving = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final activeBlue = isDark ? AppColors.primaryDark : AppColors.primary;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0C1829).withValues(alpha: 0.56) : context.cSurface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.65), width: 1.0),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16), blurRadius: 36, offset: const Offset(0, 14))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(width: 36, height: 4, decoration: BoxDecoration(color: context.cBorder.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(99))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
                    child: Row(children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 32),
                        onPressed: isSaving ? null : () => Navigator.pop(context),
                        child: Text('Cancelar', style: TextStyle(fontSize: 13.5, color: context.cTextSecondary, fontWeight: FontWeight.w500)),
                      ),
                      Expanded(child: Text(title, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: context.cTextPrimary, letterSpacing: -0.3))),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 32),
                        onPressed: isSaving ? null : onSave,
                        child: isSaving ? const CupertinoActivityIndicator(radius: 8) : Text(saveLabel, style: TextStyle(fontSize: 13.5, color: activeBlue, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ),
                  Divider(height: 1, thickness: 0.7, color: context.cBorder.withValues(alpha: 0.5)),
                  if (errorMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.systemRed.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.systemRed.withValues(alpha: 0.35))),
                      child: Text(errorMessage!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.systemRed)),
                    ),
                  Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(14, 12, 14, 16), child: child)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IosFormGroup extends StatelessWidget {
  final String? header;
  final List<Widget> children;

  const IosFormGroup({super.key, this.header, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (header != null)
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Text(header!.toUpperCase(), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: context.cTextSecondary)),
        ),
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : context.cSurface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.16) : context.cBorder.withValues(alpha: 0.65), width: 0.8),
            ),
            child: Column(children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) Divider(height: 1, thickness: 0.6, indent: 14, color: context.cBorder.withValues(alpha: 0.5)),
              ],
            ]),
          ),
        ),
      ),
    ]);
  }
}

class IosFormFieldRow extends StatelessWidget {
  final String label, placeholder;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  const IosFormFieldRow({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Row(children: [
        SizedBox(width: 104, child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.cTextPrimary))),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            onChanged: onChanged,
            style: TextStyle(fontSize: 13, color: context.cTextPrimary),
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              hintText: placeholder,
              hintStyle: TextStyle(fontSize: 13, color: context.cTextSecondary),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 9),
            ),
          ),
        ),
      ]),
    );
  }
}
