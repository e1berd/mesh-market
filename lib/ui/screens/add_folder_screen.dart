import 'package:declar_ui/declar_ui.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';

import '../../core/folder_id.dart';
import '../../core/models.dart';
import '../../core/pairing.dart';
import '../../i18n/strings.g.dart';
import '../../platform/storage_access.dart';
import '../../state/folders_provider.dart';
import '../../state/peers_provider.dart';
import '../../state/share_controller.dart';
import '../widgets/expressive.dart';

class _Grant {
  _Grant({this.granted = false, this.canSend = true, this.canReceive = true});
  bool granted;
  bool canSend;
  bool canReceive;
}

class AddFolderScreen extends ConsumerStatefulWidget {
  const AddFolderScreen({super.key, required this.path});

  final String path;

  @override
  ConsumerState<AddFolderScreen> createState() => _AddFolderScreenState();
}

class _AddFolderScreenState extends ConsumerState<AddFolderScreen> {
  final _name = TextEditingController();
  final _id = TextEditingController();
  final _grants = <String, _Grant>{};
  late String _path = widget.path;
  bool _idTouched = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final label = _basename(_path);
    _name.text = label;
    _id.text = slugFolderId(label);
  }

  @override
  void dispose() {
    _name.dispose();
    _id.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().isNotEmpty &&
      isValidFolderId(_id.text.trim()) &&
      !ref.read(foldersProvider.notifier).idTaken(_id.text.trim());

  void _onName(String value) {
    if (!_idTouched) _id.text = slugFolderId(value);
    setState(() {});
  }

  void _onId(String value) {
    _idTouched = value.trim().isNotEmpty;
    setState(() {});
  }

  Future<void> _changePath() async {
    if (!await ensureStorageAccess()) return;
    final picked = await FilePicker.platform.getDirectoryPath();
    if (picked == null) return;
    setState(() {
      _path = resolveAndroidDirectory(picked);
      if (!_idTouched && _name.text.trim().isEmpty) {
        final label = _basename(_path);
        _name.text = label;
        _id.text = slugFolderId(label);
      }
    });
  }

  Future<void> _submit() async {
    final peers = ref.read(pairedPeersProvider).value ?? const [];
    final id = _id.text.trim();
    setState(() => _busy = true);
    final outcome = await ref.read(foldersProvider.notifier).create(
          path: _path,
          label: _name.text.trim(),
          folderId: id,
          peers: [
            for (final peer in peers)
              if (_grants[peer.deviceId]?.granted ?? false)
                FolderPeer(
                  deviceId: peer.deviceId,
                  canSend: _grants[peer.deviceId]!.canSend,
                  canReceive: _grants[peer.deviceId]!.canReceive,
                ),
          ],
        );
    if (!mounted) return;
    if (outcome != AddFolderOutcome.added) {
      setState(() => _busy = false);
      final t = context.t;
      context.showSnackBar(
        outcome == AddFolderOutcome.idTaken
            ? t.addFolder.idTaken
            : t.addFolder.pathTaken,
      );
      return;
    }
    final folder = (ref.read(foldersProvider).value ?? const [])
        .firstWhere((f) => f.id == id);
    final share = ref.read(shareControllerProvider);
    for (final peer in peers) {
      if (_grants[peer.deviceId]?.granted ?? false) {
        await share.shareWith(folder, peer);
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final peers = ref.watch(pairedPeersProvider).value ?? const [];
    return Scaffold()
        .appBar(AppBar(title: Text(t.addFolder.title)))
        .body(
          SafeArea(
            top: false,
            child: ExpressiveResponsiveCenter(
              maxWidth: 640,
              child: ExpressiveReveal(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      _pathChip(context),
                      const SizedBox(height: 16),
                      ExpressivePanel(child: _fields(context)),
                      const SizedBox(height: 16),
                      _accessSection(context, peers),
                      const SizedBox(height: 24),
                      M3EButton(
                        onPressed: _submit,
                        enabled: _valid && !_busy,
                        size: .lg,
                        child: Text(t.addFolder.create),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
  }

  Widget _pathChip(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_rounded, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_shortPath(_path))
                .size(14)
                .weight(.w600)
                .maxLines(1)
                .overflow(.ellipsis),
          ),
          M3EButton(
            onPressed: _busy ? null : _changePath,
            style: .tonal,
            size: .sm,
            child: Text(context.t.addFolder.change),
          ),
        ],
      ),
    );
  }

  Widget _fields(BuildContext context) {
    final t = context.t;
    final id = _id.text.trim();
    final showTaken =
        id.isNotEmpty && ref.read(foldersProvider.notifier).idTaken(id);
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          onChanged: _onName,
          decoration: InputDecoration(
            labelText: t.addFolder.nameLabel,
            hintText: t.addFolder.nameHint,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _id,
          onChanged: _onId,
          decoration: InputDecoration(
            labelText: t.addFolder.idLabel,
            hintText: t.addFolder.idHint,
            errorText: showTaken ? t.addFolder.idTaken : null,
            suffixIcon: IconButton(
              tooltip: t.addFolder.idInfo,
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => _showInfo(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _accessSection(BuildContext context, List<PairingPayload> peers) {
    final t = context.t;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Text(t.addFolder.access)
            .size(13)
            .weight(.w800)
            .letterSpacing(.5)
            .color(colors.primary)
            .padding(left: 4),
        const SizedBox(height: 2),
        Text(t.addFolder.accessHint)
            .size(13)
            .color(colors.onSurfaceVariant)
            .padding(left: 4, bottom: 10),
        if (peers.isEmpty)
          Text(t.addFolder.noPeers)
              .size(14)
              .color(colors.onSurfaceVariant)
              .padding(vertical: 8)
        else
          for (final peer in peers) _peerTile(context, peer),
      ],
    );
  }

  Widget _peerTile(BuildContext context, PairingPayload peer) {
    final t = context.t;
    final colors = context.colors;
    final grant = _grants.putIfAbsent(peer.deviceId, _Grant.new);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(peer.name).size(15).weight(.w600)),
                  Switch(
                    value: grant.granted,
                    onChanged: (v) => setState(() => grant.granted = v),
                  ),
                ],
              ),
              if (grant.granted) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(t.addFolder.send).size(13).weight(.w500),
                  value: grant.canSend,
                  onChanged: (v) => setState(() => grant.canSend = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(t.addFolder.receive).size(13).weight(.w500),
                  value: grant.canReceive,
                  onChanged: (v) => setState(() => grant.canReceive = v),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    final t = context.t;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.addFolder.idInfoTitle),
        content: Text(t.addFolder.idInfoBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.addFolder.gotIt),
          ),
        ],
      ),
    );
  }
}

String _basename(String path) {
  final parts = path.split(RegExp(r'[/\\]'))..removeWhere((p) => p.isEmpty);
  return parts.isEmpty ? path : parts.last;
}

String _shortPath(String path) {
  final parts = path.split(RegExp(r'[/\\]'))..removeWhere((p) => p.isEmpty);
  if (parts.length <= 2) return path;
  return '…/${parts[parts.length - 2]}/${parts.last}';
}
