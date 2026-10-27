// lib/features/attendance/presentation/widgets/overtime_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/router/app_router.dart';
import 'overtime_option_card.dart';

/// ============================================================================
/// COMPONENTE: OvertimeSelectionDialog
/// ============================================================================
/// QUÉ HACE:
/// Despliega una hoja modal inferior para seleccionar el tipo de hora extra
/// (Entrada o Salida) y el método de verificación (Facial con IA o GPS directo).
///
/// PARA QUÉ SIRVE:
/// Otorga control exacto sobre el registro de horas adicionales a la jornada laboral,
/// cumpliendo con las regulaciones de control de personal de Talento Humano.
///
/// PRINCIPIOS SOLID APLICADOS:
/// - S (Single Responsibility): Exclusivamente captura la intención de horas extras.
/// ============================================================================
class OvertimeSelectionDialog extends StatelessWidget {
  final Future<void> Function(String tipo)? onDirectRegister;

  const OvertimeSelectionDialog({super.key, this.onDirectRegister});

  static Future<void> show(
    BuildContext context, {
    Future<void> Function(String tipo)? onDirectRegister,
  }) {
    return showIosFloatingGlassSheet<void>(
      context: context,
      title: 'Registro de Horas Extras',
      subtitle: 'Selecciona la acción a marcar',
      child: OvertimeSelectionDialog(onDirectRegister: onDirectRegister),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Opción 1: Entrada Hora Extra
            OvertimeOptionCard(
              title: 'Entrada Hora Extra',
              subtitle: 'Comienzo de labor adicional autorizada',
              icon: Icons.more_time_rounded,
              color: const Color(0xFFD97706),
              onTapFacial: () {
                Navigator.pop(context);
                context.push(
                    '${AppRoutes.facialRecognition}?tipo=hora_extra_entrada');
              },
              onTapDirect: onDirectRegister != null
                  ? () {
                      Navigator.pop(context);
                      onDirectRegister!('hora_extra_entrada');
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            // Opción 2: Salida Hora Extra
            OvertimeOptionCard(
              title: 'Salida Hora Extra',
              subtitle: 'Fin del turno extraordinario',
              icon: Icons.timer_off_rounded,
              color: const Color(0xFF8B5CF6),
              onTapFacial: () {
                Navigator.pop(context);
                context.push(
                    '${AppRoutes.facialRecognition}?tipo=hora_extra_salida');
              },
              onTapDirect: onDirectRegister != null
                  ? () {
                      Navigator.pop(context);
                      onDirectRegister!('hora_extra_salida');
                    }
                  : null,
            ),
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}
