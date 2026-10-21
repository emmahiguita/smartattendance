import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

// Fade Animation
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

// Scale Animation
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

// Hover Elevation Animation
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

// Loading Skeleton
class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.cBorder.withValues(alpha: 0.3),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      )
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .shimmer(
            duration: const Duration(milliseconds: 1500),
            color: context.cBorder.withValues(alpha: 0.5),
          ),
    );
  }
}

// Card Skeleton
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.cSurface,
        border: Border.all(color: context.cBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LoadingSkeleton(
                  width: 48,
                  height: 48,
                  borderRadius: BorderRadius.all(Radius.circular(12))),
              LoadingSkeleton(
                  width: 80,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(20))),
            ],
          ),
          SizedBox(height: 20),
          LoadingSkeleton(width: 120, height: 36),
          SizedBox(height: 8),
          LoadingSkeleton(width: 100, height: 16),
          SizedBox(height: 16),
          LoadingSkeleton(width: double.infinity, height: 40),
        ],
      ),
    );
  }
}

// Table Row Skeleton
class TableRowSkeleton extends StatelessWidget {
  const TableRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: const Row(
        children: [
          LoadingSkeleton(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.all(Radius.circular(12))),
          SizedBox(width: 16),
          Expanded(flex: 2, child: LoadingSkeleton(width: 150, height: 16)),
          SizedBox(width: 16),
          Expanded(flex: 1, child: LoadingSkeleton(width: 100, height: 16)),
          SizedBox(width: 16),
          Expanded(flex: 1, child: LoadingSkeleton(width: 100, height: 16)),
          SizedBox(width: 16),
          Expanded(
              flex: 1,
              child: LoadingSkeleton(
                  width: 80,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(20)))),
          SizedBox(width: 16),
          Expanded(flex: 1, child: LoadingSkeleton(width: 80, height: 16)),
          SizedBox(width: 80),
        ],
      ),
    );
  }
}

// Count Animation
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
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.target.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
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
        return Text(
          _animation.value.round().toString(),
          style: widget.style,
        );
      },
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }
}

// Staggered Animation for Lists
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
          delay:
              Duration(milliseconds: entry.key * staggerDelay.inMilliseconds),
          child: entry.value,
        );
      }).toList(),
    );
  }
}

// Ripple Effect Button
class RippleButton extends StatefulWidget {
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
  State<RippleButton> createState() => _RippleButtonState();
}

class _RippleButtonState extends State<RippleButton> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        splashColor:
            widget.rippleColor ?? AppColors.primary.withValues(alpha: 0.2),
        highlightColor:
            widget.rippleColor ?? AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: widget.child,
      ),
    );
  }
}

// Slide In Animation
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

// Pulse Animation for Alerts
class PulseAlert extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const PulseAlert({
    super.key,
    required this.child,
    this.isActive = true,
  });

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
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseAlert oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

// Shimmer Effect for Loading
class ShimmerLoading extends StatelessWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .shimmer(
            duration: const Duration(milliseconds: 1500),
            color: context.cBorder.withValues(alpha: 0.3),
          ),
    );
  }
}
