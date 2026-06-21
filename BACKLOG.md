# Backlog / known issues

Tracked gaps and follow-ups. Phases refer to the implementation plan.

## Blocking real two-device sync
- [x] **Folder-share protocol.** `FolderShare {id, label, swarmSecret}` in
  `core/folder_share.dart`; `FoldersNotifier.shareOf/addPeer/acceptShare` let two devices
  converge on one `folder.id` + `swarmSecret`.
- [x] **Mutual + camera-free pairing (backend).** Beacon broadcasts full identity
  (`lan_beacon.dart`); `PairRequest`/`PairResponse` handshake in `sync_service.dart` updates
  **both** devices; confirm-on-receiver via `onIncomingPair` + verification `pairingCode`.
  Providers: `nearbyDevicesProvider`, `incomingPairProvider`, `pairingControllerProvider`
  (`pairByPayload`).
- [x] **Pairing UI** (`pair_screen.dart` + `manual_pair_dialog.dart`): Nearby devices list
  (`nearbyDevicesProvider`, one-tap Pair → `pairByPayload`), manual paste, QR routed through
  the mutual `pairByPayload`, and an incoming-pair confirmation dialog (name + verification
  code) wired to `incomingPairProvider`. Watching the Pair screen activates discovery.
  Strings added to `i18n/*.i18n.yaml` (regenerate with `dart run slang`).
- [x] Cross-network pairing rendezvous: `pairByCode` / `SyncService.pairViaCode` — both devices
  enter the same code, meet on the DHT under `hash('point-machine/pair/<code>')`, then run the
  mutual pairing handshake. UI: "Pair over the internet" on the Pair screen.
- [ ] **NAT traversal for WAN** (the real remaining limit): `pairAt`/sync use a direct TCP
  connection to the discovered endpoint, which only works when a peer is reachable (public IP,
  port-forward, or VPN like Tailscale). General home-NAT traversal needs UDP hole punching
  (or carrying WebRTC SDP/ICE over the DHT, which `bittorrent_dht` 0.0.15 can't store — BEP5
  only), or an optional self-hosted relay. Applies to both cross-network pairing and WAN sync.
- [x] **Folder-share handshake (backend).** `ShareRequest`/`ShareResponse` in
  `sync_service.dart` (`shareFolder` / `_handleShare`); `shareControllerProvider.shareWith`
  adds the peer + sends the share; receiver confirms via `incomingShareProvider`. Both sides
  end up with the same `folder.id`+`swarmSecret` and each other in `peerIds` → sync engages.
- [ ] **Folder-share UI (second agent, M3E + animations).** Folders screen: a per-folder
  "Share with…" action listing paired peers (`pairedPeersProvider`) → `shareControllerProvider
  .shareWith(folder, peer)`. Incoming-share confirmation from `incomingShareProvider`: show
  sender + folder label, let the user pick a local directory (`FilePicker.getDirectoryPath`),
  then `foldersProvider.notifier.acceptShare(share, path, fromDeviceId)` and
  `incomingShareProvider.notifier.resolve(pending, true)` (or `false` to reject).
- [x] **SyncService provider.** `state/sync_provider.dart` builds `FolderRuntime`s and
  runs/stops `SyncService`, rebuilding on identity/config/peers/folders changes. **Remaining:**
  something in the widget tree must `ref.watch(syncServiceProvider)` to activate it.

## Transport correctness (needs live verification — not unit-testable here)
- [ ] WebRTC negotiation race: responder must attach its listener before the initiator's
  offer arrives; current ordering relies on RTT margin. Verify on real devices.
- [ ] Trailing-ICE handling closes the signaling channel 3s after the data channel opens —
  heuristic; revisit for slow/WAN links.
- [ ] LAN beacon uses `reusePort` — may throw on Windows; verify per platform.
- [ ] DHT bootstrap/NAT hole-punching unverified; confirm peers actually connect over WAN.

## Security (Phase 5+)
- [x] Wire-level confidentiality: every block is sealed with XChaCha20-Poly1305 before it
  enters the (already DTLS-encrypted) data channel — the user's "no one can read the files"
  requirement for transfer.
- [ ] At-rest encryption scope: the user's synced folder must stay plaintext (else files are
  unusable), so at-rest applies to (a) the identity/key store — use `flutter_secure_storage`
  (OS keychain) instead of plaintext `identity.json`, and (b) future untrusted/replica peers.
- [ ] Signed-challenge auth in the handshake (today: paired-id check + folder-key secrecy).

## Engine / sync
- [x] Conflict resolution — concurrent edits create `.sync-conflict-*` copies and keep
  local (engine `_consider`, covered by test).
- [ ] Deletion propagation: covered in `_consider`, add an explicit test.
- [ ] Transfer resume after disconnect (re-request only missing blocks across sessions).
- [ ] Large files are read fully into memory in scanner/serve; stream instead for big files.

## UI / UX (second agent's domain)
- [ ] Copy-Device-ID buttons are placeholders (`onPressed: () {}`).
- [x] Activity screen wired to live sync events: engine/service emit `SyncEvent`s
  (connected/disconnected/received/conflict) → `syncEventsProvider` → `activity_screen.dart`
  renders them (M3E card list).
- [ ] `file_picker.getDirectoryPath` on Android/iOS is limited; rethink folder selection on mobile.

## Background / tray (Phase 6)
- [x] Desktop tray + close-to-tray keep-alive (`platform/desktop_tray.dart`,
  `platform/background.dart`, wired in `main.dart`): window hides on close, restores from
  tray, Quit destroys it. Tray setup is guarded so a missing icon never blocks startup.
- [ ] **Tray icon asset**: add `assets/tray.png` (+ `assets/tray.ico` for Windows) and declare
  it under `flutter: assets:` in `pubspec.yaml`; otherwise the tray icon won't appear.
- [ ] **Android foreground service** (`flutter_background_service`) + **iOS BGTask**
  (`workmanager`): keep sync alive in the background. Needs a background isolate entrypoint
  that re-bootstraps identity/db/folders and runs `SyncService` (providers don't cross
  isolates) — best done with on-device testing.
- [ ] Launch-on-login (desktop) and battery-optimization exemption prompt (Android).

## Platform / build
- [ ] Linux native build (handled by another agent): `flutter_webrtc` `uint32_t` missing
  `<cstdint>`, `tray_manager` `app_indicator_new` deprecation under `-Werror` (clang-21,
  Ubuntu 26.04). CMake/snap issue already resolved (non-snap Flutter in `~/flutter`).
- [ ] iOS background sync is OS-limited; surface honestly in UI.
