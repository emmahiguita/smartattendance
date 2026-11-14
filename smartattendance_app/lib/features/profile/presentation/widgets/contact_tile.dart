// ============================================================================
// ARCHIVO: contact_tile.dart
// QUÉ HACE: Widget interactivo táctil para cada canal de contacto oficial:
//           - WhatsApp, Gmail y GitHub.
//           - Muestra ícono distintivo, título del canal, handle y flecha de apertura.
// CÓMO FUNCIONA: Al tocar el tile ejecuta feedback háptico e invoca `launchUrl`
//                en la aplicación externa correspondiente del sistema operativo.
// POR QUÉ: Diseño modular (< 110 líneas) limpio, profesional y reusable sin
//          recargas visuales vibe-coder.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ContactTile extends StatelessWidget {
  const ContactTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String url;

  // QUÉ HACE: Abre el enlace externo en el navegador o app nativa.
  // CÓMO: Emplea `url_launcher` con `LaunchMode.externalApplication`.
  // POR QUÉ: Asegura la navegación real e inmediata del usuario.
  Future<void> _handleTap(BuildContext context) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No fue posible abrir el canal seleccionado.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al conectar con la aplicación externa.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final textPrimary = context.cTextPrimary;
    final textSecondary = context.cTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.arrow_up_right,
                size: 15,
                color: textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
