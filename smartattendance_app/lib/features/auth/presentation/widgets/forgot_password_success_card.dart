// ============================================================================
// ARCHIVO: forgot_password_success_card.dart
// QUÉ HACE: Tarjeta Liquid Glass de confirmación exitosa de restablecimiento.
// CÓMO FUNCIONA: Muestra icono de verificación, mensaje devuelto por el backend
//                y botón de retorno directo al login.
// POR QUÉ: Separa la vista de éxito para cumplir la regla de modularidad (< 200 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/ios_glass_card.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/primary_button.dart';

class ForgotPasswordSuccessCard extends StatelessWidget {
  const ForgotPasswordSuccessCard({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return IosGlassCard(
      padding: const EdgeInsets.all(28),
      borderRadius: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.systemGreen.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, size: 52, color: AppColors.systemGreen),
          ),
          const SizedBox(height: 20),
          Text(
            'Contraseña actualizada',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.editorialSerif,
              fontFamilyFallback: AppTheme.editorialFallbacks,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.cTextPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message.isNotEmpty ? message : 'Tu contraseña se ha restablecido exitosamente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: context.cTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 26),
          PrimaryButton(
            label: 'Ir a iniciar sesión',
            expanded: true,
            onPressed: () => context.go(AppRoutes.login),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.96, 0.96));
  }
}
