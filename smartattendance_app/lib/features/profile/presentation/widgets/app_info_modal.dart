// ============================================================================
// ARCHIVO: app_info_modal.dart
// QUÉ HACE: Modal institucional oficial de BuenTiempo y su autoría técnica:
//           - Nombre de la app: BuenTiempo v1.0.0 (Build 2026.1).
//           - Año de creación: 2026.
//           - Creador: Emmanuel Higuita (dev emm ai).
//           - Perfil: Analista y Desarrollador de Software · Programador · QA.
//           - Licencia: Software Propietario / Licencia Privada Comercial.
//           - Canales táctiles directos: WhatsApp, Gmail y GitHub.
// CÓMO FUNCIONA: Muestra hoja flotante Liquid Glass con tipografía sobria,
//                eliminando datos personales innecesarios (sin C.C.) y enlaces reales.
// POR QUÉ: Cumple la regla de arquitectura limpia, modular (< 220 líneas) y profesional.
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/design_system/ios_floating_glass_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import 'contact_tile.dart';

// QUÉ HACE: Despliega la hoja modal flotante con la ficha técnica oficial.
// CÓMO: Invoca `showIosFloatingGlassSheet` conteniendo `AppInfoModalContent`.
// POR QUÉ: Presentación visual fluida y centrada sin alterar navegación de fondo.
Future<void> showAppInfoModal(BuildContext context) {
  return showIosFloatingGlassSheet(
    context: context,
    title: 'Información Institucional',
    subtitle: 'BuenTiempo · Versión 2026',
    child: const AppInfoModalContent(),
  );
}

class AppInfoModalContent extends StatelessWidget {
  const AppInfoModalContent({super.key});

  static const String creatorName = 'Emmanuel Higuita';
  static const String creatorAlias = 'dev emm ai';
  static const String creatorRole = 'Analista y Desarrollador de Software · Programador · QA';
  static const String creationYear = '2026';
  static const String licenseType = 'Software Propietario / Licencia Privada Comercial';

  // QUÉ HACE: Copia la ficha técnica y de contacto profesional al portapapeles.
  // CÓMO: Escribe en el portapapeles del SO y genera respuesta háptica.
  // POR QUÉ: Facilita compartir datos formales de contacto y autoría.
  void _copyTechnicalSheet(BuildContext context) {
    const text = '''
=== FICHA TÉCNICA OFICIAL ===
Aplicación: ${AppConfig.appName} v${AppConfig.appVersion}
Año de Creación: $creationYear
Creador: $creatorName ($creatorAlias)
Perfil: $creatorRole
Licencia: $licenseType
Derechos: © $creationYear $creatorName. Todos los derechos reservados.
WhatsApp: +57 320 352 7283 (https://wa.me/573203527283)
Correo: eememeai@gmail.com
GitHub: https://github.com/emmahiguita
''';
    Clipboard.setData(const ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ficha técnica copiada al portapapeles.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _sectionTitle(String title, BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: context.cTextSecondary,
          ),
        ),
      );

  Widget _glassCard(BuildContext context, {required List<Widget> children}) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : context.cSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.10) : context.cBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _infoRow(String label, String value, BuildContext context, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: context.cTextSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                color: context.cTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bloque 1: Aplicación y Año
          _glassCard(
            context,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.clock_fill, color: primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppConfig.appName} v${AppConfig.appVersion}',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.cTextPrimary),
                        ),
                        Text(
                          'Año de Creación: $creationYear · Local-First Core',
                          style: TextStyle(fontSize: 11.5, color: context.cTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Bloque 2: Autoría y Perfil Profesional
          _sectionTitle('AUTORÍA Y DESARROLLO', context),
          _glassCard(
            context,
            children: [
              _infoRow('Creador:', creatorName, context, isHighlight: true),
              _infoRow('Firma:', creatorAlias, context),
              _infoRow('Perfil:', creatorRole, context),
            ],
          ),

          // Bloque 3: Propiedad Intelectual y Licenciamiento
          _sectionTitle('PROPIEDAD Y LICENCIA', context),
          _glassCard(
            context,
            children: [
              _infoRow('Licencia:', licenseType, context),
              _infoRow('Copyright:', '© $creationYear $creatorName ($creatorAlias)', context),
              _infoRow('Modelo:', 'Local-First Inmutable · SQLite Seguro', context),
            ],
          ),

          // Bloque 4: Canales de Contacto Directo Táctiles
          _sectionTitle('CANALES DE CONTACTO OFICIALES', context),
          _glassCard(
            context,
            children: const [
              ContactTile(
                icon: CupertinoIcons.chat_bubble_2_fill,
                title: 'WhatsApp Oficial',
                subtitle: '+57 320 352 7283',
                url: 'https://wa.me/573203527283',
              ),
              Divider(height: 1, indent: 46),
              ContactTile(
                icon: CupertinoIcons.mail_solid,
                title: 'Correo Electrónico (Gmail)',
                subtitle: 'eememeai@gmail.com',
                url: 'mailto:eememeai@gmail.com',
              ),
              Divider(height: 1, indent: 46),
              ContactTile(
                icon: CupertinoIcons.chevron_left_slash_chevron_right,
                title: 'GitHub y Repositorio',
                subtitle: 'github.com/emmahiguita',
                url: 'https://github.com/emmahiguita',
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Botonera de Acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyTechnicalSheet(context),
                  icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 15),
                  label: const Text('Copiar Ficha', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cerrar', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
