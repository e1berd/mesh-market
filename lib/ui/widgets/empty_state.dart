import 'package:declar_ui/declar_ui.dart';

class EmptyState extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Column(
        mainAxisSize: .min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: 20),
          Text(title)
              .size(18)
              .weight(.w700)
              .color(colors.onSurface)
              .align(.center),
          if (message != null)
            Text(message!)
                .size(14)
                .color(colors.onSurfaceVariant)
                .align(.center)
                .padding(top: 8),
          if (action != null) action!.padding(top: 24),
        ],
      ).padding(horizontal: 48),
    );
  }
}
