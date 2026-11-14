// ============================================================================
// ARCHIVO: remember_session_toggle.dart
// QUÉ HACE: Renderiza el control accesible para conservar la sesión local.
// CÓMO: Sincroniza toda la fila y el checkbox con el mismo callback booleano.
// POR QUÉ: Aísla una responsabilidad visual y evita desbordes de texto móvil.
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class RememberSessionToggle extends StatelessWidget {
  const RememberSessionToggle({
    super.key,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: value,
                  activeColor: activeColor,
                  onChanged: (next) => onChanged(next ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recordar sesión en este dispositivo',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.cTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
