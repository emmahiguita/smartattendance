// lib/features/attendance/presentation/widgets/smart_punch_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// ============================================================================
/// COMPONENTE: SmartPunchCard (Tarjeta Inteligente de Próxima Marcación)
/// ============================================================================
/// QUÉ HACE:
/// Proyecta el llamado a la acción primario del colaborador:
/// calcula visualmente cuál es la siguiente marcación obligatoria según la
/// secuencia de la jornada (Entrada -> Almuerzo -> Regreso -> Salida).
///
/// CÓMO FUNCIONA:
/// Recibe [nextTipo] y determina color, icono, título y disparador
/// de apertura biométrica facial mediante un [InkWell] con respuesta háptica.
///
/// POR QUÉ:
/// Principio de Responsabilidad Única (SRP):
/// Desacoplado del cuerpo general de la pantalla para evitar re-renderizados
/// masivos cuando cambian estados ajenos (ej. geolocalización o listas).
///
/// PRINCIPIOS SOLID:
/// - S (Single Responsibility): Exclusivamente responsable de renderizar el botón de acción principal.
/// - O (Open/Closed): Fácilmente extensible con nuevos tipos de marcaciones o turnos especiales.
/// ============================================================================
class SmartPunchCard extends StatelessWidget {
  final String nextTipo;
  final VoidCallback onTap;

  const SmartPunchCard({
    super.key,
    required this.nextTipo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determinación de tokens visuales según el estado de la jornada
    final (label, icon, color) = switch (nextTipo) {
      'entrada' => (
        'REGISTRAR ENTRADA',
        Icons.login_rounded,
        AppColors.primary,
      ),
      'salida_almuerzo' => (
        'REGISTRAR INICIO DE ALMUERZO',
        Icons.restaurant_rounded,
        const Color(0xFFF59E0B),
      ),
      'regreso_almuerzo' => (
        'REGISTRAR REGRESO DE ALMUERZO',
        Icons.work_history_rounded,
        const Color(0xFF10B981),
      ),
      'salida' => (
        'REGISTRAR SALIDA',
        Icons.logout_rounded,
        const Color(0xFFEF4444),
      ),
      _ => (
        'REGISTRAR ENTRADA',
        Icons.camera_alt_rounded,
        AppColors.primary,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icono representativo del hito de asistencia
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                // Etiqueta y descripción
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'PRÓXIMA MARCACIÓN',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: color,
                                letterSpacing: 0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: context.cTextPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Apertura facial biométrica instantánea',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.cTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Flecha indicadora de acción
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
