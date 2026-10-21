import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_design_tokens.dart';

/// ============================================================================
/// COMPONENTE: PerspectiveFlipCard
/// ============================================================================
/// Tarjeta con rotación tridimensional en el eje Y, corrección de perspectiva,
/// descarte de cara oculta (backface culling) para evitar reflejos de texto,
/// prevención de toques en la cara inactiva y soporte integral de accesibilidad.
class PerspectiveFlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final Duration duration;
  final Curve curve;
  final bool initialFlipped;
  final ValueChanged<bool>? onFlip;
  final bool enableTapToFlip;
  final bool showFlipButton;
  final String flipSemanticLabel;

  const PerspectiveFlipCard({
    super.key,
    required this.front,
    required this.back,
    this.duration = AppDesignTokens.durationFlip,
    this.curve = AppDesignTokens.curveFlip,
    this.initialFlipped = false,
    this.onFlip,
    this.enableTapToFlip = true,
    this.showFlipButton = false,
    this.flipSemanticLabel = 'Girar tarjeta de identificación',
  });

  @override
  State<PerspectiveFlipCard> createState() => PerspectiveFlipCardState();
}

class PerspectiveFlipCardState extends State<PerspectiveFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late bool _isFlipped;

  bool get isFlipped => _isFlipped;

  @override
  void initState() {
    super.initState();
    _isFlipped = widget.initialFlipped;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: _isFlipped ? 1.0 : 0.0,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isFlipped = true;
        widget.onFlip?.call(true);
      } else if (status == AnimationStatus.dismissed) {
        _isFlipped = false;
        widget.onFlip?.call(false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Voltea la tarjeta programáticamente
  void flip() {
    if (MediaQuery.of(context).disableAnimations) {
      setState(() {
        _isFlipped = !_isFlipped;
        _controller.value = _isFlipped ? 1.0 : 0.0;
        widget.onFlip?.call(_isFlipped);
      });
      return;
    }
    if (_controller.isAnimating) return;
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  void flipToFront() {
    if (MediaQuery.of(context).disableAnimations) {
      setState(() {
        _isFlipped = false;
        _controller.value = 0.0;
        widget.onFlip?.call(false);
      });
      return;
    }
    if (_isFlipped && !_controller.isAnimating) {
      _controller.reverse();
    }
  }

  void flipToBack() {
    if (MediaQuery.of(context).disableAnimations) {
      setState(() {
        _isFlipped = true;
        _controller.value = 1.0;
        widget.onFlip?.call(true);
      });
      return;
    }
    if (!_isFlipped && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Semantics(
      label: widget.flipSemanticLabel,
      button: widget.enableTapToFlip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enableTapToFlip ? flip : null,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final value = disableAnimations
                ? (_isFlipped ? 1.0 : 0.0)
                : _animation.value;
            final angle = value * math.pi;
            final isFrontVisible = value < 0.5;

            // Matriz con perspectiva Y (0.0015 da una profundidad óptica natural)
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle);

            return Transform(
              transform: transform,
              alignment: Alignment.center,
              child: isFrontVisible
                  ? IgnorePointer(
                      ignoring: !isFrontVisible,
                      child: widget.front,
                    )
                  // Cara posterior: compensamos la rotación con math.pi para que
                  // el texto y los iconos NO aparezcan invertidos ni reflejados.
                  : Transform(
                      transform: Matrix4.identity()..rotateY(math.pi),
                      alignment: Alignment.center,
                      child: IgnorePointer(
                        ignoring: isFrontVisible,
                        child: widget.back,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}
