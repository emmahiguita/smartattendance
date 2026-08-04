// lib/shared/widgets/primary_button.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable primary action button with loading state.
/// SRP: only renders a button, delegates action to callback.
/// Theme-driven: colores del ElevatedButtonTheme (funciona en light y dark).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isPill = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isPill;

  /// True → ocupa todo el ancho disponible (botones de formulario full-width).
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isPill ? 999 : DesignTokens.radiusSmall,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 18),
                ],
              ],
            ),
    );

    return AnimatedScale(
      scale: isLoading ? .97 : 1.0,
      duration: const Duration(milliseconds: 150),
      child:
          expanded ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
