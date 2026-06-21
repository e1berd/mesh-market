import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:motor/motor.dart';

const expressiveDuration = Duration(milliseconds: 520);
const expressiveFastDuration = Duration(milliseconds: 260);
const expressiveCurve = Easing.emphasizedDecelerate;
const expressiveExitCurve = Easing.emphasizedAccelerate;

const _springReveal = M3EMotion.expressiveSpatialDefault;
const _springFast = M3EMotion.expressiveEffectsFast;
const _springScale = M3EMotion.expressiveSpatialFast;

class ExpressiveSwitcher extends StatelessWidget {
  const ExpressiveSwitcher({
    super.key,
    required this.child,
    this.duration = expressiveDuration,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: expressiveFastDuration,
      switchInCurve: expressiveCurve,
      switchOutCurve: expressiveExitCurve,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: expressiveCurve,
          reverseCurve: expressiveExitCurve,
        );
        return FadeTransition(opacity: curved, child: child);
      },
      child: child,
    );
  }
}

class ExpressivePageSwitcher extends StatelessWidget {
  const ExpressivePageSwitcher({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PageTransitionSwitcher(
      duration: expressiveDuration,
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
        return FadeThroughTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          fillColor: colors.surfaceContainerLowest,
          child: child,
        );
      },
      child: child,
    );
  }
}

class ExpressiveReveal extends StatefulWidget {
  const ExpressiveReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<ExpressiveReveal> createState() => _ExpressiveRevealState();
}

class _ExpressiveRevealState extends State<ExpressiveReveal>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = SingleMotionController(
      motion: _springReveal.toMotion(),
      vsync: this,
      initialValue: 0,
    );

    if (widget.delay == Duration.zero) {
      _controller.animateTo(1);
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.animateTo(1);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final value = _controller.value;
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * widget.offset),
            child: Transform.scale(
              scale: .98 + (.02 * value),
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class ExpressiveSection extends StatelessWidget {
  const ExpressiveSection({
    super.key,
    required this.title,
    required this.children,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 16),
  });

  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExpressiveReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          AnimatedContainer(
            duration: expressiveFastDuration,
            curve: expressiveCurve,
            margin: margin,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: .32),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: AnimatedSize(
              duration: expressiveDuration,
              curve: expressiveCurve,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 72,
                        color: colors.outlineVariant.withValues(alpha: .42),
                      ),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpressiveIconContainer extends StatelessWidget {
  const ExpressiveIconContainer({
    super.key,
    required this.icon,
    this.color,
    this.foregroundColor,
    this.size = 52,
    this.radius = 18,
  });

  final IconData icon;
  final Color? color;
  final Color? foregroundColor;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: expressiveFastDuration,
      curve: expressiveCurve,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? colors.primaryContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        icon,
        color: foregroundColor ?? colors.onPrimaryContainer,
        size: size * .48,
      ),
    );
  }
}

class ExpressiveStatusPill extends StatelessWidget {
  const ExpressiveStatusPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.foregroundColor,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fg = foregroundColor ?? colors.onTertiaryContainer;
    return AnimatedContainer(
      duration: expressiveFastDuration,
      curve: expressiveCurve,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class ExpressiveSpringScale extends StatefulWidget {
  const ExpressiveSpringScale({
    super.key,
    required this.child,
    this.pressed = false,
    this.active = false,
    this.selected = false,
  });

  final Widget child;
  final bool pressed;
  final bool active;
  final bool selected;

  @override
  State<ExpressiveSpringScale> createState() => _ExpressiveSpringScaleState();
}

class _ExpressiveSpringScaleState extends State<ExpressiveSpringScale>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SingleMotionController(
      motion: _springScale.toMotion(),
      vsync: this,
      initialValue: _target,
    );
  }

  @override
  void didUpdateWidget(ExpressiveSpringScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pressed != widget.pressed ||
        oldWidget.active != widget.active ||
        oldWidget.selected != widget.selected) {
      _controller.animateTo(_target);
    }
  }

  double get _target => widget.pressed
      ? .96
      : widget.active || widget.selected
          ? 1
          : .98;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Transform.scale(
        scale: _controller.value,
        child: child,
      ),
    );
  }
}

class ExpressiveSpringContainer extends StatefulWidget {
  const ExpressiveSpringContainer({
    super.key,
    required this.decoration,
    this.child,
    this.width,
    this.height,
    this.padding,
  });

  final Decoration decoration;
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  @override
  State<ExpressiveSpringContainer> createState() =>
      _ExpressiveSpringContainerState();
}

class _ExpressiveSpringContainerState extends State<ExpressiveSpringContainer>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _controller;
  Decoration? _previousDecoration;

  @override
  void initState() {
    super.initState();
    _controller = SingleMotionController(
      motion: _springFast.toMotion(),
      vsync: this,
      initialValue: 1,
    );
    _previousDecoration = widget.decoration;
  }

  @override
  void didUpdateWidget(ExpressiveSpringContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.decoration != widget.decoration) {
      _previousDecoration = oldWidget.decoration;
      _controller
        ..stop(canceled: true)
        ..value = 0
        ..animateTo(1);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final current = _lerpDecoration(_previousDecoration, widget.decoration, t);
        return AnimatedContainer(
          duration: Duration.zero,
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: current,
          child: child,
        );
      },
    );
  }

  Decoration? _lerpDecoration(Decoration? a, Decoration? b, double t) {
    if (a == null || b == null) return b;
    return Decoration.lerp(a, b, t);
  }
}
