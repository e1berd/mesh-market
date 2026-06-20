# Backlog / known issues

Tracked gaps and follow-ups. Phases refer to the implementation plan.

## Blocking real two-device sync
- [ ] **Folder-share protocol (Phase 5).** Two devices must converge on the same
  `folder.id` + `swarmSecret`; today each device generates its own, so infohashes differ
  and peers never meet. Need a `FolderShare {id, label, swarmSecret}` exchanged via QR or
  over a paired connection, plus `FoldersNotifier.acceptShare/shareWith`.
- [ ] **QR camera scan (UI, second agent).** Decode a scanned `PairingPayload` and call
  `pairedPeersProvider.add(...)`. Logic/provider exist; needs the `mobile_scanner` widget.
- [ ] **SyncService start/stop wiring.** A provider that builds `FolderRuntime`s from
  folders + db + identity and runs/stops `SyncService` on app launch and on config changes.

## Transport correctness (needs live verification — not unit-testable here)
- [ ] WebRTC negotiation race: responder must attach its listener before the initiator's
  offer arrives; current ordering relies on RTT margin. Verify on real devices.
- [ ] Trailing-ICE handling closes the signaling channel 3s after the data channel opens —
  heuristic; revisit for slow/WAN links.
- [ ] LAN beacon uses `reusePort` — may throw on Windows; verify per platform.
- [ ] DHT bootstrap/NAT hole-punching unverified; confirm peers actually connect over WAN.

## Security (Phase 5+)
- [ ] At-rest encryption: clarify scope. The user's synced folder stays plaintext (usable);
  encrypt only untrusted/replica stores and the identity/key store. Decide and implement.
- [ ] Signed-challenge auth in the handshake (today: paired-id check + folder-key secrecy).

## Engine / sync
- [ ] Conflict resolution (Phase 5) — concurrent edits should create `.sync-conflict-*`
  copies instead of last-writer-wins.
- [ ] Deletion propagation: covered in `_consider`, add an explicit test.
- [ ] Large files are read fully into memory in scanner/serve; stream instead for big files.

## UI / UX (second agent's domain)
- [ ] Copy-Device-ID buttons are placeholders (`onPressed: () {}`).
- [ ] Activity screen is a placeholder; wire to live sync events (engine must emit events).
- [ ] `file_picker.getDirectoryPath` on Android/iOS is limited; rethink folder selection on mobile.

## Platform / build
- [ ] Linux native build (handled by another agent): `flutter_webrtc` `uint32_t` missing
  `<cstdint>`, `tray_manager` `app_indicator_new` deprecation under `-Werror` (clang-21,
  Ubuntu 26.04). CMake/snap issue already resolved (non-snap Flutter in `~/flutter`).
- [ ] iOS background sync is OS-limited; surface honestly in UI.
