// lib/features/attendance/presentation/widgets/overtime_option_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// ============================================================================
/// COMPONENTE: OvertimeOptionCard
/// ============================================================================
/// QUÉ HACE:
/// Tarjeta seleccionable para registrar entrada o salida de horas extras,
/// ofreciendo dos opciones de verificación: Reconocimiento Facial con IA o GPS.
///
/// PARA QUÉ SIRVE:
/// Proporciona una interfaz clara y ergonómica para que el trabajador elija
/// el método de validación biométrica o satelital para su tiempo extra.
///
/// PRINCIPIOS SOLID:
/// - S (Single Responsibility): Renderiza la tarjeta de opción de hora extra.
/// ============================================================================
class OvertimeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTapFacial;
  final VoidCallback? onTapDirect;

  const OvertimeOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTapFacial,
    this.onTapDirect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTapFacial,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.face_retouching_natural_rounded,
                      size: 18),
                  label: const Text('Con Rostro IA',
                      style: TextStyle(fontSize: 12.5)),
                ),
              ),
              if (onTapDirect != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onTapDirect,
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.location_on_rounded, size: 18),
                    label:
                        const Text('Con GPS', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
