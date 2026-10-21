// lib/features/attendance/presentation/widgets/admin_access_banner.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// ============================================================================
/// COMPONENTE: AdminAccessBanner (Acceso Rápido al Módulo de Talento Humano)
/// ============================================================================
/// QUÉ HACE:
/// Provee una tarjeta de acceso directo y destacada para directivos o supervisores
/// que requieran gestionar plantillas, turnos, jornadas y horas extras.
///
/// CÓMO FUNCIONA:
/// Si el rol activo o permisos lo ameritan, renderiza un botón con acción hacia
/// la pantalla administrativa de Talento Humano [AdminManagementScreen].
///
/// POR QUÉ:
/// Principio de Responsabilidad Única (SRP):
/// Desacoplado para facilitar su mantenimiento y permitir su reutilización
/// en diferentes vistas ejecutivas sin duplicar estilos ni lógica de navegación.
///
/// PRINCIPIOS SOLID:
/// - S (Single Responsibility): Exclusivamente provee el enlace visual al módulo de RRHH.
/// ============================================================================
class AdminAccessBanner extends StatelessWidget {
  final VoidCallback onNavigateToAdmin;

  const AdminAccessBanner({
    super.key,
    required this.onNavigateToAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cSurface,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icono representativo de panel corporativo
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Textos explicativos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel de Talento Humano',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: context.cTextPrimary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Gestión de plantilla, jornadas y horas extras',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.cTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Botón de acceso
          ElevatedButton(
            onPressed: onNavigateToAdmin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ver módulo',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
