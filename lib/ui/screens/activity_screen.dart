import 'package:declar_ui/declar_ui.dart';
import 'package:m3e_core/m3e_core.dart';

import '../widgets/empty_state.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        M3ECardList(
          itemCount: 1,
          itemBuilder: (ctx, i) => Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.speed_rounded,
                    color: colors.onTertiaryContainer, size: 22),
              ).padding(right: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text('0 B synced today')
                        .size(14)
                        .weight(.w600)
                        .color(colors.onSurface),
                    Text('All devices up to date')
                        .size(12)
                        .color(colors.onSurfaceVariant),
                  ],
                ),
              ),
            ],
          ),
          outerRadius: 20,
          gap: 0,
          color: colors.surfaceContainerHigh,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        ),
        const Expanded(
          child: EmptyState(
            icon: Icons.sync_rounded,
            title: 'Nothing syncing',
            message: 'Transfers and conflicts will appear here as they happen.',
          ),
        ),
      ],
    );
  }
}
