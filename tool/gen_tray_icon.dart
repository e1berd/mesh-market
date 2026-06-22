import 'dart:io';

import 'package:image/image.dart';

void main() {
  final source = decodePng(File('assets/icon/orbit-1024-foreground.png').readAsBytesSync())!;
  final trimmed = trim(source, mode: TrimMode.transparent);
  final pad = (trimmed.width * 0.12).round();
  final glyph = Image(
    width: trimmed.width + pad * 2,
    height: trimmed.height + pad * 2,
    numChannels: 4,
  );
  compositeImage(glyph, trimmed, dstX: pad, dstY: pad);

  final tray = copyResize(glyph, width: 192, height: 192, interpolation: Interpolation.cubic);
  File('assets/tray.png').writeAsBytesSync(encodePng(tray));

  final icoSizes = [16, 24, 32, 48, 64, 128, 256];
  final frames = icoSizes
      .map((s) => copyResize(glyph, width: s, height: s, interpolation: Interpolation.cubic))
      .toList();
  File('assets/tray.ico').writeAsBytesSync(IcoEncoder().encodeImages(frames));

  stdout.writeln('tray.png 192x192 and tray.ico (${icoSizes.join(",")}) written');
}
