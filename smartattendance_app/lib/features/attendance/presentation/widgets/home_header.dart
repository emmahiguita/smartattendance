// ============================================================================
// ARCHIVO: home_header.dart
// QUÉ HACE: Encabezado institucional con tipografía Editorial Profesional
//           (`AppTheme.editorialSerif`), saludo personalizado, cargo y fecha.
// CÓMO FUNCIONA: Combina Serif de alto contraste en el saludo y la inicial del
//                avatar con versalitas espaciadas en el sello institucional.
// POR QUÉ: Aplica el sistema de fuentes Editorial Profesional (< 125 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  final dynamic user;
  final VoidCallback? onOpenDirectory;

  const HomeHeader({
    super.key,
    required this.user,
    this.onOpenDirectory,
  });

  String _formatDate() {
    final now = DateTime.now();
    try {
      final df = DateFormat("EEEE, d 'de' MMMM", 'es_ES');
      final formatted = df.format(now);
      return formatted[0].toUpperCase() + formatted.substring(1);
    } catch (_) {
      return '${now.day}/${now.month}/${now.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final fullName = (user?.fullName as String? ?? 'Colaborador');
    final firstName = fullName.split(' ').first;
    final cargo = (user?.cargo as String? ?? 'Operativo');
    final dateStr = _formatDate();
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'C';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
          child: Text(
            initial,
            style: const TextStyle(
              fontFamily: AppTheme.editorialSerif,
              fontFamilyFallback: AppTheme.editorialFallbacks,
              fontFeatures: AppTheme.editorialFeatures,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.08),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'SERVICIUDAD E.S.P.',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: AppColors.primary,
                        fontFeatures: AppTheme.editorialFeatures,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cargo,
                      style: TextStyle(
                        fontFamily: AppTheme.editorialSerif,
                        fontFamilyFallback: AppTheme.editorialFallbacks,
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.cTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '¡Hola, $firstName!',
                style: TextStyle(
                  fontFamily: AppTheme.editorialSerif,
                  fontFamilyFallback: AppTheme.editorialFallbacks,
                  fontFeatures: AppTheme.editorialFeatures,
                  fontSize: 19.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.35,
                  color: context.cTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11.2,
                  letterSpacing: 0.1,
                  color: context.cTextSecondary,
                  fontWeight: FontWeight.w500,
                  fontFeatures: AppTheme.editorialFeatures,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
