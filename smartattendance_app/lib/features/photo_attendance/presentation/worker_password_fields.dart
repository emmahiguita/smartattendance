// ============================================================================
// ARCHIVO: worker_password_fields.dart
// QUÉ HACE: Permite activar una cuenta con contraseña individual y confirmación
//           en filas compactas estilo iOS unificadas con el resto del formulario.
// CÓMO FUNCIONA: Presenta dos filas de contraseña con ícono lateral, etiqueta
//                alineada y divisor fino de 0.5px sin subrayados duplicados.
// POR QUÉ: Unifica el diseño iOS dentro de `WorkerDialogFields` (< 80 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class WorkerPasswordFields extends StatelessWidget {
  const WorkerPasswordFields({
    super.key,
    required this.password,
    required this.confirmation,
  });

  final TextEditingController password, confirmation;

  Widget _row(
    BuildContext context, {
    required Key fieldKey,
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    final isDark = context.isDark;
    final iconBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final iconColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(CupertinoIcons.lock_fill, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.cTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              key: fieldKey,
              controller: controller,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: context.cTextPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: context.cTextSecondary.withValues(alpha: 0.65),
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final div = Divider(
      height: 1,
      thickness: 0.5,
      indent: 38,
      color: context.cBorder.withValues(alpha: 0.35),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        div,
        _row(
          context,
          fieldKey: const ValueKey('worker-initial-password'),
          label: 'Contraseña',
          hint: 'Mín. 8 caract. (Mayús, minús, #)',
          controller: password,
        ),
        div,
        _row(
          context,
          fieldKey: const ValueKey('worker-confirm-password'),
          label: 'Confirmar',
          hint: 'Repite la contraseña inicial',
          controller: confirmation,
        ),
      ],
    );
  }
}
