import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'app_design_tokens.dart';

/// ============================================================================
/// COMPONENTE: Interactive3DTurntable
/// ============================================================================
/// Mesa giratoria interactiva sobre el eje Y con perspectiva óptica 2.5D,
/// inercia física, fricción de desaceleración gradual, interrupción al toque
/// y soporte para reducción de movimiento.
class Interactive3DTurntable extends StatefulWidget {
  final Widget child;
  final double perspective;
  final double friction;
  final double maxAngle; // en radianes, por ejemplo +/- 0.6 rad o pi
  final bool autoReset;
  final Duration resetDuration;
  final ValueChanged<double>? onAngleChanged;
  final String semanticLabel;

  const Interactive3DTurntable({
    super.key,
    required this.child,
    this.perspective = 0.0012,
    this.friction = 0.92,
    this.maxAngle = math.pi / 3, // +/- 60 grados para sobriedad
    this.autoReset = true,
    this.resetDuration = AppDesignTokens.durationMedium,
    this.onAngleChanged,
    this.semanticLabel = 'Elemento interactivo 3D con rotación horizontal',
  });

  @override
  State<Interactive3DTurntable> createState() => _Interactive3DTurntableState();
}

class _Interactive3DTurntableState extends State<Interactive3DTurntable>
    with SingleTickerProviderStateMixin {
  double _angle = 0.0;
  double _velocity = 0.0;
  Ticker? _ticker;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;
  double _startAngleBeforeReset = 0.0;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: widget.resetDuration,
    )..addListener(() {
        setState(() {
          _angle = _resetAnimation.value;
          widget.onAngleChanged?.call(_angle);
        });
      });
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _resetController.dispose();
    super.dispose();
  }

  void _onDragDown(DragDownDetails details) {
    // Interrupción inmediata de inercia o reset al tocar
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _resetController.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (MediaQuery.of(context).disableAnimations) return;

    // Sensibilidad al arrastre horizontal
    final delta = details.primaryDelta ?? 0.0;
    final angleDelta = (delta / 140.0);

    setState(() {
      _angle = (_angle + angleDelta).clamp(-widget.maxAngle, widget.maxAngle);
      widget.onAngleChanged?.call(_angle);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (MediaQuery.of(context).disableAnimations) return;

    final pixelsPerSecond = details.primaryVelocity ?? 0.0;
    _velocity = (pixelsPerSecond / 1000.0) * 0.05;

    // Si tiene velocidad apreciable, arranca la física de inercia con fricción
    if (_velocity.abs() > 0.005) {
      _ticker?.dispose();
      _ticker = createTicker(_onTick)..start();
    } else if (widget.autoReset) {
      _startReset();
    }
  }

  void _onTick(Duration elapsed) {
    _velocity *= widget.friction;
    final newAngle = (_angle + _velocity).clamp(-widget.maxAngle, widget.maxAngle);

    if ((newAngle - _angle).abs() < 0.0005 ||
        newAngle == -widget.maxAngle ||
        newAngle == widget.maxAngle) {
      _ticker?.stop();
      _ticker?.dispose();
      _ticker = null;
      if (widget.autoReset) {
        _startReset();
      }
      return;
    }

    setState(() {
      _angle = newAngle;
      widget.onAngleChanged?.call(_angle);
    });
  }

  void _startReset() {
    _startAngleBeforeReset = _angle;
    _resetAnimation = Tween<double>(
      begin: _startAngleBeforeReset,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _resetController,
        curve: AppDesignTokens.curveEntrance,
      ),
    );
    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    final transform = Matrix4.identity()
      ..setEntry(3, 2, widget.perspective)
      ..rotateY(disableAnimations ? 0.0 : _angle);

    return Semantics(
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragDown: _onDragDown,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: Transform(
          transform: transform,
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
