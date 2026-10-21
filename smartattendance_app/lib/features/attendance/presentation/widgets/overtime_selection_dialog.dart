// lib/features/attendance/presentation/widgets/overtime_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
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
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          OvertimeSelectionDialog(onDirectRegister: onDirectRegister),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.more_time_rounded,
                      color: Color(0xFFD97706)),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registro de Horas Extras',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Selecciona la acción a marcar',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
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
      ),
    );
  }
}
