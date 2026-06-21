import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class DesktopTray with TrayListener, WindowListener {
  DesktopTray({required this.iconPath, required this.onQuit});

  final String iconPath;
  final Future<void> Function() onQuit;

  Future<void> setup() async {
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);

    await trayManager.setIcon(iconPath);
    await trayManager.setToolTip('point-machine');
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'show', label: 'Open point-machine'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Quit'),
    ]));
    trayManager.addListener(this);
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        windowManager.show();
        windowManager.focus();
      case 'quit':
        _quit();
    }
  }

  @override
  void onWindowClose() => windowManager.hide();

  Future<void> _quit() async {
    await onQuit();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  Future<void> dispose() async {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
  }
}
