// lib/features/attendance/presentation/widgets/smart_punch_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// ============================================================================
/// COMPONENTE: SmartPunchCard (Acceso a la marcación)
/// ============================================================================
/// QUÉ HACE:
/// Abre el directorio local de trabajadores desde la portada.
///
/// CÓMO FUNCIONA:
/// El operador elige un trabajador y la pantalla de selección obtiene su
/// siguiente marca desde los datos locales antes de abrir la cámara.
///
/// POR QUÉ:
/// Principio de Responsabilidad Única (SRP):
/// Desacoplado del cuerpo general de la pantalla para evitar re-renderizados
/// masivos cuando cambian estados ajenos (ej. geolocalización o listas).
///
/// PRINCIPIOS SOLID:
/// - S (Single Responsibility): Exclusivamente responsable de renderizar el botón de acción principal.
/// - O (Open/Closed): El componente no depende de tipos de marca individuales.
/// ============================================================================
class SmartPunchCard extends StatelessWidget {
  final VoidCallback onTap;

  const SmartPunchCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Cada trabajador puede tener una marca distinta como siguiente paso.
    const label = 'Seleccionar trabajador';
    const icon = Icons.camera_alt_rounded;
    const color = AppColors.primary;

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
                  child: const Icon(icon, color: color, size: 24),
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
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              'REGISTRO DE ASISTENCIA',
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
                        'La marca sigue la jornada de cada persona',
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
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
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
