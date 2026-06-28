import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/conflict.dart';
import '../../core/text_diff.dart';
import '../../i18n/strings.g.dart';

class ConflictDiffView extends StatelessWidget {
  const ConflictDiffView({super.key, required this.conflict});

  final FolderConflict conflict;

  Future<List<DiffRow>?> _load() async {
    final incomingFile = File(conflict.conflictPath);
    if (!await incomingFile.exists()) return null;
    final incoming = decodeText(await incomingFile.readAsBytes());
    final originalFile = File(conflict.originalPath);
    final originalBytes =
        await originalFile.exists() ? await originalFile.readAsBytes() : <int>[];
    final current = decodeText(originalBytes);
    if (current == null || incoming == null) return null;
    return diffLines(current, incoming);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<List<DiffRow>?>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data;
        if (rows == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.t.folders.conflictNoPreview,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _tag(context, context.t.folders.conflictCurrent)),
                const SizedBox(width: 8),
                Expanded(
                  child: _tag(context, context.t.folders.conflictIncoming),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ColoredBox(
                  color: colors.surfaceContainerLow,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: rows.length,
                    itemBuilder: (context, index) => _DiffRowView(row: rows[index]),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tag(BuildContext context, String label) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: colors.primary,
      ),
    );
  }
}

class _DiffRowView extends StatelessWidget {
  const _DiffRowView({required this.row});

  final DiffRow row;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final leftHighlighted =
        row.kind == DiffKind.removed || row.kind == DiffKind.changed;
    final rightHighlighted =
        row.kind == DiffKind.added || row.kind == DiffKind.changed;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _cell(
              row.left,
              leftHighlighted ? colors.errorContainer : Colors.transparent,
              leftHighlighted ? colors.onErrorContainer : colors.onSurfaceVariant,
            ),
          ),
          Container(width: 1, color: colors.outlineVariant),
          Expanded(
            child: _cell(
              row.right,
              rightHighlighted
                  ? colors.tertiaryContainer
                  : Colors.transparent,
              rightHighlighted
                  ? colors.onTertiaryContainer
                  : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String? text, Color background, Color foreground) => Container(
    color: background,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    child: Text(
      text ?? '',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        height: 1.35,
        color: foreground,
      ),
    ),
  );
}
