import 'dart:io';

import 'package:flutter/services.dart';
import 'package:nativeapi/nativeapi.dart';
import 'package:path/path.dart' as p;

class DesktopTray {
  DesktopTray({required this.iconPath, required this.onQuit});

  final String iconPath;
  final Future<void> Function() onQuit;

  late final TrayIcon _trayIcon;
  late final WindowManager _windowManager;
  late final Window _window;

  Future<void> setup() async {
    _windowManager = WindowManager.instance;
    _window = _windowManager.getCurrent()!;

    final image = await _resolveImage();

    _trayIcon = TrayIcon();
    if (image != null) _trayIcon.icon = image;
    _trayIcon.tooltip = 'point-machine';
    _trayIcon.contextMenuTrigger = ContextMenuTrigger.rightClicked;

    final menu = Menu();
    final showItem = MenuItem('Open point-machine');
    showItem.on<MenuItemClickedEvent>((_) {
      _window.show();
      _window.focus();
    });
    menu.addItem(showItem);
    menu.addSeparator();
    final quitItem = MenuItem('Quit');
    quitItem.on<MenuItemClickedEvent>((_) => _quit());
    menu.addItem(quitItem);

    _trayIcon.contextMenu = menu;
    _trayIcon.on<TrayIconClickedEvent>((_) {
      _window.show();
      _window.focus();
    });
  }

  Future<Image?> _resolveImage() async {
    final fromAsset = Image.fromAsset(iconPath);
    if (fromAsset != null) return fromAsset;

    final exeDir = p.dirname(Platform.resolvedExecutable);
    final releasePath = p.join(exeDir, 'data', 'flutter_assets', iconPath);
    final fromFile = Image.fromFile(releasePath);
    if (fromFile != null) return fromFile;

    final bytes = await rootBundle.load(iconPath);
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/tray_icon.png');
    await tempFile.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    return Image.fromFile(tempFile.path);
  }

  Future<void> _quit() async {
    await onQuit();
    _window.dispose();
  }

  Future<void> dispose() async {
    _trayIcon.dispose();
  }
}
