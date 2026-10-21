import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// COMPONENTES DE ESTADOS: StatusStatesView
/// ============================================================================
/// Componentes reutilizables para representar de forma consistente y accesible
/// los estados operacionales: Loading, Empty, Success, Error, Offline, Disabled,
/// Pending y Unauthorized.

/// Estado de Carga (Loading)
class AppLoadingState extends StatelessWidget {
  final String message;
  const AppLoadingState({super.key, this.message = 'Cargando información…'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: AppDesignTokens.space16),
            Text(
              message,
              style: TextStyle(color: context.cTextSecondary, fontSize: 13.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado Vacío (Empty)
class AppEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.cBackgroundSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: context.cTextSecondary),
            ),
            const SizedBox(height: AppDesignTokens.space16),
            Text(
              title,
              style: AppDesignTokens.title(color: context.cTextPrimary, fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(color: context.cTextSecondary, fontSize: 13.5),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDesignTokens.space16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, AppDesignTokens.minTouchTargetSize),
                ),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de Éxito (Success) con check animado sobrio (300–450 ms)
class AppSuccessCheck extends StatefulWidget {
  final String message;
  final VoidCallback? onDone;
  final Duration duration;

  const AppSuccessCheck({
    super.key,
    required this.message,
    this.onDone,
    this.duration = AppDesignTokens.durationSuccess,
  });

  @override
  State<AppSuccessCheck> createState() => _AppSuccessCheckState();
}

class _AppSuccessCheckState extends State<AppSuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppDesignTokens.curveBounce,
    );
    _controller.forward().then((_) => widget.onDone?.call());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.systemGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: AppDesignTokens.space16),
          Text(
            widget.message,
            style: AppDesignTokens.title(color: context.cTextPrimary, fontSize: 17),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Estado de Error con transición sobria
class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    this.title = 'No se pudo completar la operación',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.systemRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 28, color: AppColors.systemRed),
            ),
            const SizedBox(height: AppDesignTokens.space16),
            Text(
              title,
              style: AppDesignTokens.title(color: context.cTextPrimary, fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(color: context.cTextSecondary, fontSize: 13.5),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDesignTokens.space16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(120, AppDesignTokens.minTouchTargetSize),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado No Autorizado (Unauthorized)
class AppUnauthorizedState extends StatelessWidget {
  final String message;
  final VoidCallback? onAction;

  const AppUnauthorizedState({
    super.key,
    this.message = 'No tienes permisos asignados para acceder a esta sección.',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.systemOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  size: 28, color: AppColors.systemOrange),
            ),
            const SizedBox(height: AppDesignTokens.space16),
            Text(
              'Acceso restringido',
              style: AppDesignTokens.title(color: context.cTextPrimary, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(color: context.cTextSecondary, fontSize: 13.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
