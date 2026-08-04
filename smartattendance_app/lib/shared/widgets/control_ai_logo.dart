// lib/shared/widgets/control_ai_logo.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Widget de marca e imagotipo oficial para CONTROL AI.
/// Renderiza el logo ejecutivo con chip IA, efectos de brillo y tipografía premium.
class ControlAiLogo extends StatelessWidget {
  final double size;
  final bool isHorizontal;
  final bool showSubtitle;
  final Color? textColor;

  const ControlAiLogo({
    super.key,
    this.size = 36,
    this.isHorizontal = true,
    this.showSubtitle = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF3B82F6),
            Color(0xFF6366F1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.15),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.memory,
          size: size * 0.55,
          color: Colors.white,
        ),
      ),
    );

    final titleText = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'CONTROL ',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: textColor ?? context.cTextPrimary,
            ),
          ),
          WidgetSpan(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
              ).createShader(bounds),
              child: Text(
                'AI',
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final subtitleText = showSubtitle
        ? Text(
            'SISTEMA INTELIGENTE DE ASISTENCIA',
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color:
                  (textColor ?? context.cTextSecondary).withValues(alpha: 0.7),
            ),
          )
        : const SizedBox.shrink();

    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          iconWidget,
          SizedBox(width: size * 0.3),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleText,
              if (showSubtitle) ...[
                const SizedBox(height: 1),
                subtitleText,
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
        iconWidget,
        SizedBox(height: size * 0.3),
        titleText,
        if (showSubtitle) ...[
          const SizedBox(height: 4),
          subtitleText,
        ],
      ],
    );
  }
}
