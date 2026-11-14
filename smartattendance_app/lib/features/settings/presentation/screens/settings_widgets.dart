// ============================================================================
// ARCHIVO: settings_widgets.dart
// QUÉ HACE: Secciones y filas de configuración estilo iOS sin tarjetas.
// CÓMO FUNCIONA: Aplica divisores finos de 0.5px, íconos neutros y espaciado
//                vertical compacto (9px) para evitar huecos entre opciones.
// POR QUÉ: Permite leer y utilizar cada opción con ritmo visual iOS (< 95 líneas).
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: context.cTextSecondary,
          ),
        ),
      );
}

/// Presenta un grupo plano con divisores finos superiores e inferiores.
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingsGroupDivider(),
          ...children,
          const SettingsGroupDivider(),
        ],
      );
}

class SettingItemRow extends StatelessWidget {
  const SettingItemRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor = Colors.grey,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title, subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Icon(icon, color: context.cTextSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: context.cTextPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.cTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      );
}

class SettingsGroupDivider extends StatelessWidget {
  const SettingsGroupDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 0.5, color: context.cBorder);
}
