import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Tarjeta reutilizable de altura natural. El texto se ajusta al espacio real
/// y al tamaño de fuente de Android, sin ocultar títulos con puntos suspensivos.
class DashboardActionCard extends StatelessWidget {
  const DashboardActionCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.icon,
      required this.accentColor,
      required this.onTap,
      this.loading = false,
      this.isRowLayout = false});
  final String title, subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool loading, isRowLayout;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10)),
        child: loading
            ? Padding(
                padding: const EdgeInsets.all(9),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: accentColor))
            : Icon(icon, size: 22, color: accentColor));
    final text = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: context.cTextPrimary,
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  color: context.cTextSecondary, fontSize: 12, height: 1.3)),
        ]);
    return Material(
        color: context.cSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: context.cBorder.withValues(alpha: 0.7))),
        child: InkWell(
            onTap: loading ? null : onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: isRowLayout
                    ? Row(children: [
                        badge,
                        const SizedBox(width: 12),
                        Expanded(child: text),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right,
                            color: context.cGray, size: 20)
                      ])
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [badge, const SizedBox(height: 10), text]))));
  }
}
