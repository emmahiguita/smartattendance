// ============================================================================
// ARCHIVO: app_info_menu_anchor.dart
// QUÉ HACE: Menú flotante compacto oficial (Material 3 MenuAnchor) para consultar:
//           - Nombre y año oficial: BuenTiempo v1.0.0 (2026).
//           - Creador: Emmanuel Higuita (dev emm ai).
//           - Perfil: Analista y Desarrollador · QA.
//           - Accesos directos táctiles a WhatsApp, Gmail y GitHub.
//           - Acceso a la Ficha Técnica y Licencia completa.
// CÓMO FUNCIONA: Despliega `MenuItemButton`s con enlaces reales mediante `url_launcher`
//                y feedback háptico sin datos personales sensibles (sin C.C.).
// POR QUÉ: Diseño limpio, profesional (< 140 líneas) y adaptado a M3 y Apple HIG.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../features/profile/presentation/widgets/app_info_modal.dart';

class AppInfoMenuAnchor extends StatelessWidget {
  const AppInfoMenuAnchor({super.key, this.iconColor});

  final Color? iconColor;

  Future<void> _launchUrl(String url) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final textPrimary = context.cTextPrimary;
    final textSecondary = context.cTextSecondary;

    return MenuAnchor(
      alignmentOffset: const Offset(-190, 0),
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: Icon(
            CupertinoIcons.info_circle,
            color: iconColor ?? primary,
            size: 21,
          ),
          tooltip: 'Información y Canales',
        );
      },
      menuChildren: [
        // 1. Aplicación y año
        MenuItemButton(
          leadingIcon: Icon(CupertinoIcons.clock_fill, color: primary, size: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${AppConfig.appName} v${AppConfig.appVersion}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: textPrimary)),
              Text('Año de creación: 2026', style: TextStyle(fontSize: 10.5, color: textSecondary)),
            ],
          ),
        ),

        // 2. Autoría y Perfil
        MenuItemButton(
          leadingIcon: Icon(CupertinoIcons.person_crop_circle_fill, color: primary, size: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Emmanuel Higuita · dev emm ai', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: textPrimary)),
              Text('Analista y Desarrollador · QA', style: TextStyle(fontSize: 10.5, color: textSecondary)),
            ],
          ),
        ),

        const Divider(height: 1, indent: 8, endIndent: 8),

        // 3. WhatsApp Directo
        MenuItemButton(
          leadingIcon: const Icon(CupertinoIcons.chat_bubble_2_fill, color: Color(0xFF25D366), size: 18),
          onPressed: () => _launchUrl('https://wa.me/573203527283'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('+57 320 352 7283', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary)),
              Text('WhatsApp Oficial ↗', style: TextStyle(fontSize: 10, color: textSecondary)),
            ],
          ),
        ),

        // 4. Gmail Directo
        MenuItemButton(
          leadingIcon: const Icon(CupertinoIcons.mail_solid, color: Color(0xFFEA4335), size: 18),
          onPressed: () => _launchUrl('mailto:eememeai@gmail.com'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('eememeai@gmail.com', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary)),
              Text('Correo Directo ↗', style: TextStyle(fontSize: 10, color: textSecondary)),
            ],
          ),
        ),

        // 5. GitHub Directo
        MenuItemButton(
          leadingIcon: Icon(CupertinoIcons.chevron_left_slash_chevron_right, color: textPrimary, size: 18),
          onPressed: () => _launchUrl('https://github.com/emmahiguita'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('github.com/emmahiguita', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: textPrimary)),
              Text('Repositorio & Perfil ↗', style: TextStyle(fontSize: 10, color: textSecondary)),
            ],
          ),
        ),

        const Divider(height: 1, indent: 8, endIndent: 8),

        // 6. Ver Ficha Técnica y Licencia
        MenuItemButton(
          leadingIcon: Icon(CupertinoIcons.doc_plaintext, size: 18, color: primary),
          onPressed: () => showAppInfoModal(context),
          child: Text('Ver Ficha y Licencia', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
        ),
      ],
    );
  }
}
