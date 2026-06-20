import 'package:declar_ui/declar_ui.dart';

import '../../core/config.dart';

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
      credential:
          credential.text.trim().isEmpty ? null : credential.text.trim(),
    );
  }

  return showDialog<IceServer>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('STUN / TURN server'),
      content: Column(
        mainAxisSize: .min,
        children: [
          TextField(
            controller: url,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'stun:host:3478',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: username,
            decoration: const InputDecoration(labelText: 'Username (TURN)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: credential,
            decoration: const InputDecoration(labelText: 'Credential (TURN)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, build()),
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
