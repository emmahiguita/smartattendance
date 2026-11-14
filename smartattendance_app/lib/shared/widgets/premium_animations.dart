// ============================================================================
// ARCHIVO: premium_animations.dart
// QUÉ HACE: Colección de widgets de animación reutilizables: fade, scale, slide,
//           hover elevation, ripple button, pulse alert y staggered list.
// CÓMO FUNCIONA: Cada widget envuelve un hijo con una animación específica usando
//                flutter_animate o AnimationController manual.
// POR QUÉ: Biblioteca central de motion design para toda la app (Material Expressive 3).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

// Re-exporta los skeletons para que los imports existentes sigan funcionando.
export 'premium_skeletons.dart';

// ─── ANIMACIONES DE ENTRADA ──────────────────────────────────────────────────

// QUÉ HACE: Aparición suave con opacidad de 0 → 1.
// CÓMO: Usa flutter_animate .fadeIn() con curva easeOut configurable.
// POR QUÉ: Entrada estándar para cards, textos y contenido que aparece.
class FadeIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return child.animate().fadeIn(
          duration: duration,
          delay: delay,
          curve: Curves.easeOut,
        );
  }
}

// QUÉ HACE: Entrada con escala de 0.9 → 1.0 y rebote suave.
// CÓMO: Usa flutter_animate .scale() con curva easeOutBack.
// POR QUÉ: Efecto de "pop" sutil para modales, tooltips y elementos interactivos.
class ScaleIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const ScaleIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return child.animate().scale(
          duration: duration,
          delay: delay,
          curve: Curves.easeOutBack,
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
        );
  }
}

// QUÉ HACE: Entrada deslizante desde una posición offset hasta el centro.
// CÓMO: Combina .slide() + .fadeIn() de flutter_animate.
// POR QUÉ: Efecto "slide up" para listas, paneles y contenido secuencial.
class SlideIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset beginOffset;

  const SlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.3),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .slide(
          duration: duration,
          delay: delay,
          curve: Curves.easeOut,
          begin: beginOffset,
          end: Offset.zero,
        )
        .fadeIn();
  }
}

// ─── ANIMACIONES INTERACTIVAS ────────────────────────────────────────────────

// QUÉ HACE: Eleva la sombra del hijo cuando el cursor pasa por encima (hover).
// CÓMO: MouseRegion detecta enter/exit → AnimatedContainer cambia boxShadow.
// POR QUÉ: Feedback visual para cards y botones en desktop/web.
class HoverElevation extends StatefulWidget {
  final Widget child;
  final double elevation;
  final Duration duration;

  const HoverElevation({
    super.key,
    required this.child,
    this.elevation = 8.0,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<HoverElevation> createState() => _HoverElevationState();
}

class _HoverElevationState extends State<HoverElevation> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: Offset(0, widget.elevation),
                  ),
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}

// QUÉ HACE: Botón con efecto ripple de Material 3 (onda de tinta al tocar).
// CÓMO: InkWell con splashColor/highlightColor personalizables.
// POR QUÉ: Feedback táctil estándar para cualquier widget interactivo.
class RippleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? rippleColor;

  const RippleButton({
    super.key,
    required this.child,
    this.onTap,
    this.rippleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor:
            rippleColor ?? AppColors.primary.withValues(alpha: 0.2),
        highlightColor:
            rippleColor ?? AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}

// ─── ANIMACIONES DE ESTADO ───────────────────────────────────────────────────

// QUÉ HACE: Pulso sutil (scale 1.0↔1.05) para indicar alertas activas.
// CÓMO: AnimationController con repeat(reverse: true). Se activa/desactiva
//       según el booleano isActive, limpiando el controller en dispose().
// POR QUÉ: Feedback visual para indicadores de error o notificaciones urgentes.
class PulseAlert extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const PulseAlert({super.key, required this.child, this.isActive = true});

  @override
  State<PulseAlert> createState() => _PulseAlertState();
}

class _PulseAlertState extends State<PulseAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PulseAlert oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      widget.isActive
          ? _controller.repeat(reverse: true)
          : (_controller..stop()).reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

// QUÉ HACE: Animación de contador numérico de 0 → target (ej: 0 → 42).
// CÓMO: AnimationController + Tween<double> con curva easeOut. Muestra el
//       valor redondeado en cada frame como Text.
// POR QUÉ: Efecto premium para KPIs y métricas del dashboard.
class CountAnimation extends StatefulWidget {
  final int target;
  final Duration duration;
  final TextStyle? style;

  const CountAnimation({
    super.key,
    required this.target,
    this.duration = const Duration(milliseconds: 1000),
    this.style,
  });

  @override
  State<CountAnimation> createState() => _CountAnimationState();
}

class _CountAnimationState extends State<CountAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0,
      end: widget.target.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(_animation.value.round().toString(), style: widget.style);
      },
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }
}

// QUÉ HACE: Aplica animación escalonada (stagger) a una lista de widgets.
// CÓMO: Envuelve cada hijo en FadeIn con delay incrementado por índice.
// POR QUÉ: Efecto cascada para listas de cards, empleados, registros, etc.
class StaggeredListView extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDelay;

  const StaggeredListView({
    super.key,
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.asMap().entries.map((entry) {
        return FadeIn(
          delay: Duration(
              milliseconds: entry.key * staggerDelay.inMilliseconds),
          child: entry.value,
        );
      }).toList(),
    );
  }
}
