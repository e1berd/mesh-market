import 'package:declar_ui/declar_ui.dart';

import '../../core/config.dart';
import '../../i18n/strings.g.dart';
import 'expressive.dart';

Future<IceServer?> showIceServerDialog(BuildContext context) {
  final url = TextEditingController();
  final username = TextEditingController();
  final credential = TextEditingController();

  IceServer? build() {
    final value = url.text.trim();
    if (value.isEmpty) return null;
    return IceServer(
      url: value,
      username: username.text.trim().isEmpty ? null : username.text.trim(),
      credential: credential.text.trim().isEmpty
          ? null
          : credential.text.trim(),
    );
  }

  return showDialog<IceServer>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.t.iceDialog.title),
      content: SingleChildScrollView(
        child: ExpressiveReveal(
          child: Column(
            mainAxisSize: .min,
            children: [
              TextField(
                controller: url,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.t.iceDialog.url,
                  hintText: context.t.iceDialog.urlHint,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: username,
                decoration: InputDecoration(labelText: context.t.iceDialog.username),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: credential,
                decoration: InputDecoration(
                  labelText: context.t.iceDialog.credential,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.t.iceDialog.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, build()),
          child: Text(context.t.iceDialog.add),
        ),
      ],
    ),
  );
}
