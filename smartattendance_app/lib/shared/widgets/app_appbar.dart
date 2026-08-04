// lib/shared/widgets/app_appbar.dart
import 'package:flutter/material.dart';

/// AppBar unificado para toda la aplicación
/// Evitar duplicación de código en múltiples screens
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Widget? leadingWidget;
  final bool centerTitle;
  final double elevation;

  const AppAppBar({
    required this.title,
    this.onBackPressed,
    this.actions,
    this.leadingWidget,
    this.centerTitle = true,
    this.elevation = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      title: Text(
        title,
        style: Theme.of(context).appBarTheme.titleTextStyle,
      ),
      leading: leadingWidget ??
          (onBackPressed != null
              ? IconButton(
                  onPressed: onBackPressed,
                  icon: const Icon(Icons.arrow_back_ios),
                  tooltip: 'Atrás',
                )
              : null),
      actions: actions,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Divider(
          height: 0.5,
          color: Theme.of(context).dividerTheme.color?.withValues(alpha: 0.6) ??
              Colors.grey.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 0.5);
}
