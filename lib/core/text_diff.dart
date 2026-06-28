import 'dart:convert';

enum DiffKind { equal, removed, added, changed }

class DiffRow {
  const DiffRow({this.left, this.right, required this.kind});

  final String? left;
  final String? right;
  final DiffKind kind;
}

const _maxDiffLines = 1500;

String? decodeText(List<int> bytes) {
  if (bytes.take(8000).contains(0)) return null;
  try {
    return const Utf8Decoder().convert(bytes);
  } on FormatException {
    return null;
  }
}

List<DiffRow>? diffLines(String current, String incoming) {
  final a = const LineSplitter().convert(current);
  final b = const LineSplitter().convert(incoming);
  if (a.length > _maxDiffLines || b.length > _maxDiffLines) return null;

  final n = a.length;
  final m = b.length;
  final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      dp[i][j] = a[i] == b[j]
          ? dp[i + 1][j + 1] + 1
          : (dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
    }
  }

  final rows = <DiffRow>[];
  final removed = <String>[];
  final added = <String>[];

  void flush() {
    final paired = removed.length < added.length ? removed.length : added.length;
    for (var t = 0; t < paired; t++) {
      rows.add(DiffRow(left: removed[t], right: added[t], kind: DiffKind.changed));
    }
    for (var t = paired; t < removed.length; t++) {
      rows.add(DiffRow(left: removed[t], kind: DiffKind.removed));
    }
    for (var t = paired; t < added.length; t++) {
      rows.add(DiffRow(right: added[t], kind: DiffKind.added));
    }
    removed.clear();
    added.clear();
  }

  var i = 0;
  var j = 0;
  while (i < n && j < m) {
    if (a[i] == b[j]) {
      flush();
      rows.add(DiffRow(left: a[i], right: b[j], kind: DiffKind.equal));
      i++;
      j++;
    } else if (dp[i + 1][j] >= dp[i][j + 1]) {
      removed.add(a[i]);
      i++;
    } else {
      added.add(b[j]);
      j++;
    }
  }
  while (i < n) {
    removed.add(a[i]);
    i++;
  }
  while (j < m) {
    added.add(b[j]);
    j++;
  }
  flush();
  return rows;
}
