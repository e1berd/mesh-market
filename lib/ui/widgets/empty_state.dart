import 'package:declar_ui/declar_ui.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:motor/motor.dart';

import 'expressive.dart';

class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _iconCtrl;

  @override
  void initState() {
    super.initState();
    _iconCtrl = SingleMotionController(
      motion: M3EMotion.expressiveSpatialDefault.toMotion(),
      vsync: this,
    );
    _iconCtrl.animateTo(1);
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: ExpressiveReveal(
        child: Column(
          mainAxisSize: .min,
          children: [
            AnimatedBuilder(
              animation: _iconCtrl,
              builder: (context, _) {
                final t = _iconCtrl.value;
                return Transform.scale(
                  scale: .8 + (.2 * t),
                  child: Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Container(
                      width: 96,
                      height: 88,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 40,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
            ).size(19).weight(.w800).color(colors.onSurface).align(.center),
            if (widget.message != null)
              Text(widget.message!)
                  .size(14)
                  .color(colors.onSurfaceVariant)
                  .align(.center)
                  .padding(top: 8),
            if (widget.action != null) widget.action!.padding(top: 24),
          ],
        ).padding(horizontal: 48),
      ),
    );
  }
}
