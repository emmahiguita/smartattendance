// lib/shared/widgets/control_ai_logo.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// ============================================================================
/// COMPONENTE: ControlAiLogo (Identidad Visual Corporativa iOS Style)
/// ============================================================================
/// QUÉ HACE:
/// Renderiza el imagotipo y logotipo empresarial con diseño sobrio y profesional
/// alineado a las Guías de Interfaz Humana de Apple (iOS Human Interface Guidelines).
///
/// PARA QUÉ SIRVE:
/// Provee una presencia de marca seria, confiable y universal para cualquier
/// sector productivo (servicios públicos, industria manufacturera, logística).
///
/// PRINCIPIOS SOLID:
/// - S (Single Responsibility): Exclusivamente responsable de proyectar la identidad de marca.
/// ============================================================================
class ControlAiLogo extends StatelessWidget {
  final double size;
  final bool isHorizontal;
  final bool showSubtitle;
  final Color? textColor;
  final bool iconOnly;

  const ControlAiLogo({
    super.key,
    this.size = 32,
    this.isHorizontal = true,
    this.showSubtitle = false,
    this.textColor,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Emblema biométrico estilo iOS: Squircle con degradado sutil
    final emblemWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.shield_rounded,
          size: size * 0.52,
          color: AppColors.systemBlue,
        ),
      ),
    );

    if (iconOnly) {
      return emblemWidget;
    }

    // 2. Tipografía empresarial sobria (Cero colores estridentes estilo vibecoding)
    final titleWidget = Text(
      'AsistenciaPro',
      style: TextStyle(
        fontSize: size * 0.52,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: textColor ?? context.cTextPrimary,
      ),
    );

    final subtitleWidget = showSubtitle
        ? Text(
            'GESTIÓN DE TALENTO HUMANO',
            style: TextStyle(
              fontSize: size * 0.24,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: (textColor ?? context.cTextSecondary).withValues(alpha: 0.75),
            ),
          )
        : const SizedBox.shrink();

    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          emblemWidget,
          SizedBox(width: size * 0.32),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              if (showSubtitle) ...[
                const SizedBox(height: 2),
                subtitleWidget,
              ],
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        emblemWidget,
        SizedBox(height: size * 0.35),
        titleWidget,
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          subtitleWidget,
        ],
      ],
    );
  }
}
