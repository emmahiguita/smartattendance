import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Kit de botones al estilo iOS nativo (Cupertino).
class AppButtons {
  /// Botón principal azul iOS (Filled)
  static Widget primary({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.41,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Botón secundario iOS (Tonal) — fondo contextual (claro en light, oscuro en dark)
  static Widget secondary({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: context.cGray5,
        borderRadius: BorderRadius.circular(14),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.systemBlue, size: 22),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                color: AppColors.systemBlue,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.41,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Botón sin fondo (Texto interactivo iOS)
  static Widget outline({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.systemBlue, size: 22),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: const TextStyle(
              color: AppColors.systemBlue,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.41,
            ),
          ),
        ],
      ),
    );
  }

  /// Botón "Iniciar sesión con Google" — conectado al flujo REAL de Google
  /// Sign-In (id_token → POST /auth/google). [onPressed] null = deshabilitado.
  static Widget googleAuth({
    required BuildContext context,
    required VoidCallback? onPressed,
    String text = "Continuar con Google",
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.systemGray4, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 16),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
              height: 22,
              width: 22,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.android, color: AppColors.systemGray),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.41,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── MATERIAL 3 ICON BUTTONS (Adaptados a iOS) ─────────────────────────────

  static Widget iconStandard({
    required VoidCallback onPressed,
    required IconData icon,
    Color? color,
    double size = 24.0,
    String? tooltip,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Icon(icon, size: size, color: color ?? AppColors.systemBlue),
    );
  }

  static Widget iconFilled({
    required VoidCallback onPressed,
    required IconData icon,
    Color? backgroundColor,
    Color? iconColor,
    double size = 24.0,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.systemBlue,
        shape: BoxShape.circle,
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        onPressed: onPressed,
        child: Icon(icon, size: size, color: iconColor ?? Colors.white),
      ),
    );
  }

  static Widget iconTonal({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData icon,
    Color? backgroundColor,
    Color? iconColor,
    double size = 24.0,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? context.cGray5,
        shape: BoxShape.circle,
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        onPressed: onPressed,
        child: Icon(icon, size: size, color: iconColor ?? AppColors.systemBlue),
      ),
    );
  }

  static Widget iconOutlined({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData icon,
    Color? borderColor,
    Color? iconColor,
    double size = 24.0,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor ?? context.cGray4),
        shape: BoxShape.circle,
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(8),
        onPressed: onPressed,
        child: Icon(icon, size: size, color: iconColor ?? context.cGray),
      ),
    );
  }
}
