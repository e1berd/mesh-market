import 'package:declar_ui/declar_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../core/conflict.dart';
import '../../i18n/strings.g.dart';
import '../../state/conflict_controller.dart';
import '../../state/conflicts_provider.dart';
import 'conflict_diff_view.dart';

void showConflictSheet(BuildContext context, String folderId) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ConflictSheet(folderId: folderId),
  );
}

class _ConflictSheet extends ConsumerStatefulWidget {
  const _ConflictSheet({required this.folderId});

  final String folderId;

  @override
  ConsumerState<_ConflictSheet> createState() => _ConflictSheetState();
}

class _ConflictSheetState extends ConsumerState<_ConflictSheet> {
  int _selected = 0;
  bool _closing = false;

  void _scheduleClose() {
    if (_closing) return;
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  Future<void> _auto() async {
    await ref.read(conflictControllerProvider).resolveAll(widget.folderId);
    if (mounted) context.showSnackBar(context.t.folders.conflictResolved);
  }

  Future<void> _keepCurrent(FolderConflict conflict) async {
    await ref.read(conflictControllerProvider).keepCurrent(conflict);
    if (mounted) setState(() => _selected = 0);
  }

  Future<void> _useIncoming(FolderConflict conflict) async {
    await ref.read(conflictControllerProvider).useIncoming(conflict);
    if (mounted) setState(() => _selected = 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final async = ref.watch(folderConflictsProvider(widget.folderId));

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t.folders.conflictsTitle,
                    ).size(20).weight(.w800),
                  ),
                  M3EButton.icon(
                    onPressed: _auto,
                    icon: const Icon(Icons.auto_fix_high_rounded),
                    label: Text(context.t.folders.resolveAuto),
                    style: .tonal,
                    size: .sm,
                  ),
                ],
              ),
              Text(
                context.t.folders.resolveAutoHint,
              ).size(12).color(colors.onSurfaceVariant).padding(top: 2, bottom: 12),
              Expanded(
                child: async.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('$error')),
                  data: (list) {
                    if (list.isEmpty) {
                      _scheduleClose();
                      return const SizedBox.shrink();
                    }
                    final selected = _selected.clamp(0, list.length - 1);
                    final conflict = list[selected];
                    return Column(
                      crossAxisAlignment: .stretch,
                      children: [
                        if (list.length > 1) ...[
                          _Selector(
                            conflicts: list,
                            selected: selected,
                            onSelect: (i) => setState(() => _selected = i),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Text(conflict.name)
                            .size(15)
                            .weight(.w700)
                            .maxLines(1)
                            .overflow(.ellipsis),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ConflictDiffView(
                            key: ValueKey(conflict.conflictPath),
                            conflict: conflict,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: M3EButton(
                                onPressed: () => _keepCurrent(conflict),
                                style: .tonal,
                                child: Text(context.t.folders.conflictKeepCurrent),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: M3EButton(
                                onPressed: () => _useIncoming(conflict),
                                child: Text(context.t.folders.conflictUseIncoming),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  const _Selector({
    required this.conflicts,
    required this.selected,
    required this.onSelect,
  });

  final List<FolderConflict> conflicts;
  final int selected;
  final void Function(int index) onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: conflicts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final active = index == selected;
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: active
                  ? colors.secondaryContainer
                  : colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(conflicts[index].name)
                .size(12)
                .weight(.w700)
                .color(
                  active ? colors.onSecondaryContainer : colors.onSurfaceVariant,
                ),
          ).onTap(() => onSelect(index));
        },
      ),
    );
  }
}
