final _slugChar = RegExp(r'[\p{L}\p{N}]', unicode: true);

String slugFolderId(String name) {
  final buffer = StringBuffer();
  var pendingDash = false;
  for (final rune in name.trim().toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    if (_slugChar.hasMatch(char)) {
      if (pendingDash && buffer.isNotEmpty) buffer.write('-');
      buffer.write(char);
      pendingDash = false;
    } else {
      pendingDash = true;
    }
  }
  return buffer.toString();
}

bool isValidFolderId(String id) => id.isNotEmpty && id == slugFolderId(id);
