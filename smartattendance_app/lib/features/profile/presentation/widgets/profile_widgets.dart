// ============================================================================
// ARCHIVO: profile_widgets.dart
// QUÉ HACE: Presenta expediente y acciones de perfil como filas iOS compactas.
// CÓMO FUNCIONA: Coloca divisor superior e inferior de 0.5px por sección y
//                reduce el padding vertical (9px) para evitar huecos amplios.
// POR QUÉ: Logra una estética iOS limpia y uniforme (< 95 líneas).
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.header,
    required this.children,
  });

  final String header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              header,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: context.cTextSecondary,
              ),
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: context.cBorder),
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            Divider(
              height: 1,
              thickness: 0.5,
              indent: i < children.length - 1 ? 32 : 0,
              color: context.cBorder,
            ),
          ],
        ],
      );
}

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow(this.icon, this.label, this.value, {super.key});
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: context.cTextSecondary),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: context.cTextSecondary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.cTextPrimary,
                ),
              ),
            ),
          ],
        ),
      );
}

class ProfileActionRow extends StatelessWidget {
  const ProfileActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: context.cTextSecondary, size: 19),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: context.cTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
              ),
              trailing ??
                  Icon(
                    CupertinoIcons.chevron_forward,
                    color: context.cTextSecondary,
                    size: 15,
                  ),
            ],
          ),
        ),
      );
}
