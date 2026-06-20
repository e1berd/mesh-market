import 'package:declar_ui/declar_ui.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../i18n/strings.g.dart';
import '../widgets/empty_state.dart';
import '../widgets/expressive.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          ExpressiveReveal(
            child: M3ECardList(
              itemCount: 1,
              itemBuilder: (ctx, i) => Row(
                children: [
                  ExpressiveIconContainer(
                    icon: Icons.speed_rounded,
                    color: colors.tertiaryContainer,
                    foregroundColor: colors.onTertiaryContainer,
                    size: 48,
                    radius: 18,
                  ).padding(right: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          context.t.activity.syncedToday(bytes: '0 B'),
                        ).size(15).weight(.w800).color(colors.onSurface),
                        Text(
                          context.t.activity.upToDate,
                        ).size(12).color(colors.onSurfaceVariant),
                      ],
                    ),
                  ),
                ],
              ),
              outerRadius: 32,
              innerRadius: 12,
              gap: 0,
              color: colors.surfaceContainerHigh,
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            ),
          ),
          Expanded(
            child: EmptyState(
              icon: Icons.sync_rounded,
              title: context.t.activity.empty,
              message: context.t.activity.emptyHint,
            ),
          ),
        ],
      ),
    );
  }
}
