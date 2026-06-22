import 'dart:async';

import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:motor/motor.dart';

const expressiveDuration = Duration(milliseconds: 520);
const expressiveFastDuration = Duration(milliseconds: 260);
const expressiveCurve = Easing.emphasizedDecelerate;
const expressiveExitCurve = Easing.emphasizedAccelerate;
const expressiveCompactBreakpoint = 720.0;
const expressiveMediumBreakpoint = 900.0;
const expressiveExpandedBreakpoint = 1200.0;
const expressiveListOuterRadius = 24.0;
const expressiveListInnerRadius = 4.0;
const expressiveListGap = 3.0;
const expressiveListPadding = EdgeInsets.all(12);
const expressiveListMargin = EdgeInsets.symmetric(horizontal: 12);

const _springReveal = M3EMotion.expressiveSpatialDefault;
const _springFast = M3EMotion.expressiveEffectsFast;
const _springScale = M3EMotion.expressiveSpatialFast;

bool expressiveHasBottomNav(BuildContext context) =>
    MediaQuery.sizeOf(context).width < expressiveCompactBreakpoint;

EdgeInsets expressiveScreenPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final horizontal = width >= expressiveExpandedBreakpoint
      ? 32.0
      : width >= expressiveCompactBreakpoint
      ? 24.0
      : 16.0;
  return EdgeInsets.fromLTRB(
    horizontal,
    width >= expressiveCompactBreakpoint ? 16 : 8,
    horizontal,
    expressiveHasBottomNav(context) ? 96 : 28,
  );
}

EdgeInsets expressiveListPaddingFor(BuildContext context) {
  return EdgeInsets.only(bottom: expressiveScreenPadding(context).bottom);
}

int expressiveGridColumns(
  BuildContext context, {
  double minTileWidth = 360,
  int maxColumns = 3,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < expressiveMediumBreakpoint) return 1;
  final available = width - expressiveScreenPadding(context).horizontal;
  return (available / minTileWidth).floor().clamp(2, maxColumns);
}

class ExpressiveResponsiveCenter extends StatelessWidget {
  const ExpressiveResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? expressiveScreenPadding(context),
          child: child,
        ),
      ),
    );
  }
}

class ExpressivePanel extends StatelessWidget {
  const ExpressivePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 32,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: expressiveFastDuration,
      curve: expressiveCurve,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

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

class ExpressiveLazyStack extends StatefulWidget {
  const ExpressiveLazyStack({
    super.key,
    required this.index,
    required this.length,
    required this.itemBuilder,
  });

  final int index;
  final int length;
  final Widget Function(int index) itemBuilder;

  @override
  State<ExpressiveLazyStack> createState() => _ExpressiveLazyStackState();
}

class _ExpressiveLazyStackState extends State<ExpressiveLazyStack> {
  final _visited = <int>{};
  final _cache = <int, Widget>{};

  @override
  void initState() {
    super.initState();
    _visited.add(widget.index);
    WidgetsBinding.instance.addPostFrameCallback((_) => _warmNext());
  }

  void _warmNext() {
    if (!mounted || _visited.length >= widget.length) return;
    for (var i = 0; i < widget.length; i++) {
      if (_visited.add(i)) break;
    }
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _warmNext());
  }

  @override
  void didUpdateWidget(ExpressiveLazyStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _visited.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.length; i++)
          _visited.contains(i)
              ? _cache.putIfAbsent(
                  i,
                  () => RepaintBoundary(child: widget.itemBuilder(i)),
                )
              : const SizedBox.shrink(),
      ],
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
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) {
        final value = _controller.value.clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, (1 - value) * widget.offset),
          child: Transform.scale(
            scale: .98 + (.02 * value),
            alignment: Alignment.topCenter,
            child: child,
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
    this.margin = EdgeInsets.zero,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExpressiveReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                ?trailing,
              ],
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

class OrbitLogo extends StatelessWidget {
  const OrbitLogo({
    super.key,
    this.size = 40,
    this.containerColor,
    this.onContainerColor,
  });

  final double size;
  final Color? containerColor;
  final Color? onContainerColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size.square(size),
      painter: _OrbitLogoPainter(
        container: containerColor ?? colors.primaryContainer,
        onContainer: onContainerColor ?? colors.onPrimaryContainer,
      ),
    );
  }
}

class _OrbitLogoPainter extends CustomPainter {
  _OrbitLogoPainter({required this.container, required this.onContainer});

  final Color container;
  final Color onContainer;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 1024;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(230 * s),
    );
    canvas.drawRRect(rrect, Paint()..color = container);

    canvas.drawCircle(
      Offset(512 * s, 512 * s),
      195 * s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 56 * s
        ..color = onContainer,
    );

    final dotFill = Paint()..color = onContainer;
    final dotEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24 * s
      ..color = container;
    for (final dot in const [Offset(650, 374), Offset(374, 650)]) {
      final center = Offset(dot.dx * s, dot.dy * s);
      canvas.drawCircle(center, 78 * s, dotFill);
      canvas.drawCircle(center, 78 * s, dotEdge);
    }
  }

  @override
  bool shouldRepaint(_OrbitLogoPainter old) =>
      old.container != container || old.onContainer != onContainer;
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
      builder: (context, child) =>
          Transform.scale(scale: _controller.value, child: child),
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
        final current = _lerpDecoration(
          _previousDecoration,
          widget.decoration,
          t,
        );
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
