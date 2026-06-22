import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nativeapi/nativeapi.dart';
import 'package:path/path.dart' as p;

class DesktopTray {
  DesktopTray({required this.iconPath, required this.onQuit});

  static const appName = 'Point Machine';

  final String iconPath;
  final Future<void> Function() onQuit;

  TrayIcon? _trayIcon;
  late final WindowManager _windowManager;
  Window? _window;

  Future<void> setup() async {
    _windowManager = WindowManager.instance;
    for (var attempt = 0; attempt < 5; attempt++) {
      _window = _windowManager.getCurrent();
      if (_window != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    if (_window == null) return;

    final image = await _resolveImage();

    _trayIcon = TrayIcon();
    final tray = _trayIcon!;
    if (image != null) tray.icon = image;
    tray.tooltip = appName;
    tray.contextMenuTrigger = ContextMenuTrigger.clicked;

    final menu = Menu();
    final showItem = MenuItem('Open $appName');
    showItem.on<MenuItemClickedEvent>((_) => _open());
    menu.addItem(showItem);
    menu.addSeparator();
    final quitItem = MenuItem('Quit');
    quitItem.on<MenuItemClickedEvent>((_) => _quit());
    menu.addItem(quitItem);

    tray.contextMenu = menu;
    tray.on<TrayIconRightClickedEvent>((_) => tray.openContextMenu());
    tray.on<TrayIconDoubleClickedEvent>((_) => _open());
    tray.isVisible = true;

    _enableAutostart();
  }

  void _open() {
    _window?.show();
    _window?.focus();
  }

  void hideToTray() => _window?.hide();

  void _enableAutostart() {
    try {
      if (!LaunchAtLogin.isSupported) return;
      final launch = LaunchAtLogin(
        id: 'tech.hammerhead.point_machine',
        displayName: appName,
      );
      launch.setProgram(Platform.resolvedExecutable, const ['--hidden']);
      if (!launch.isEnabled) launch.enable();
    } on Object catch (error, stack) {
      debugPrint('[pm.tray] autostart failed: $error\n$stack');
    }
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
    _window?.dispose();
    exit(0);
  }

  Future<void> dispose() async {
    _trayIcon?.dispose();
  }
}
