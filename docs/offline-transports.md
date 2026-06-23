# Offline Transports — Implementation Spec

Handoff spec for the agent implementing the remaining offline (no-internet) transports.
Read this **and** the files it references before writing code. Everything here is grounded in
the current codebase; file paths and line ranges are approximate but real.

---

## 0. Goal

mesh-market already syncs over three transports: **directTcp** (LAN sockets), **localNetwork**
(WebRTC), and **bluetooth** (BLE/GATT). The task is to add the remaining *near-field / offline*
transports so two paired devices can sync with **zero IP uplink** (no Wi-Fi router, no internet),
and with **high throughput** where BLE is too slow.

Transports to add, in priority order of value:

1. **Wi-Fi Direct** — high-bandwidth P2P over the Wi-Fi radio, no access point. (Android + desktop)
2. **MultipeerConnectivity** — Apple's BLE+peer-Wi-Fi framework. (iOS + macOS)
3. **Soft-AP / local hotspot** — one device raises a hotspot, peers join, reuse LAN path. (universal fallback)
4. **NFC pairing handoff** — tap-to-pair, complements existing QR. (discovery/pairing only)
5. **Wi-Fi Aware (NAN)** — serverless discovery + data path. (Android 8+, lower priority)
6. ~~Nearby Connections~~ — **evaluated and rejected**, see §11(1). Google-SDK / GMS dependency and
   architectural friction outweigh the convenience; build the discrete transports above instead.

**Hard constraints (from `CLAUDE.md`, non-negotiable):**
- **No server of ours, ever** — including for discovery. None of these transports may introduce one.
- **No C/C++ — ever.** Platform bridges must be **Kotlin (Android)** or **Swift (Apple)**. That is
  allowed and expected; it is not the forbidden "native FFI module."
- **Max 300 lines per file.** Split transports the way `tcp_transport.dart` / `bluetooth_transport.dart` are.
- **No explanatory comments.** Self-documenting names only.
- **Dot shorthands** (`.system`, `.filled`) wherever the language allows.
- UI (settings toggles) must be **Material 3 Expressive** via `m3e_core` / `declar_ui`, `context.colors.*`.
- Use **`dart analyze` / `dart test`**, never `flutter analyze` / `flutter test` (they crash in this env).

---

## 1. The contract every transport must satisfy

### 1.1 `PeerLink` — `lib/transport/peer_link.dart`

```dart
abstract interface class PeerLink {
  String get peerId;
  Stream<SyncMessage> get incoming;
  Future<void> send(SyncMessage message);
  Future<void> close();
}
```

A transport delivers a `PeerLink`. The sync engine drives it; **the transport is a dumb pipe** that
carries `SyncMessage` objects faithfully and in order. `SyncMessage.encode()/decode()` (see
`lib/transport/messages.dart`) gives you `Uint8List` framing payloads.

### 1.2 Encryption is NOT your job

`SyncService._runLink` (`lib/sync/sync_service.dart:589`) wraps every session in a `FolderCipher`
derived per peer+folder (`deriveFolderKey`, XChaCha20-Poly1305). **All transports inherit E2E
sealing for free** — do not add or skip your own crypto at the transport layer.

> Transit note to document in `SECURITY` / README: non-WebRTC transports (BLE, Multipeer over its own
> channel, Wi-Fi Direct raw socket) do **not** get WebRTC DTLS. Confidentiality/integrity of file
> bytes still holds via the per-folder cipher at the engine layer. State this explicitly; a reviewer
> will ask. (IP-yielding transports that reuse `TcpPeerLink` are plaintext on the wire but still E2E-sealed.)

### 1.3 Transport class shape (copy the existing pattern)

Model every transport on `DirectTcpTransport` (`lib/transport/tcp_transport.dart`) and
`BluetoothTransport` (`lib/transport/bluetooth_transport.dart`):

```dart
class XxxIncomingLink { final String peerId; final String folderId; final PeerLink link; }

class XxxTransport {
  XxxTransport({required this.deviceId, required this.deviceName});
  static Future<bool> isSupported();           // hardware/OS capability probe (see §5.1)
  Stream<XxxIncomingLink> get incoming;        // inbound sessions (we are the "server")
  Future<void> start();                         // idempotent; guarded by a config flag
  Future<PeerLink> open({required String peerId, required String folderId});  // outbound dial
  Future<void> stop();
}
```

`isSupported()` must report whether the **device** can do this transport at all (e.g. no NFC chip,
no BLE peripheral role, no Wi-Fi Aware on this OS). It drives capability-gated Settings (§5.1) — a
hard requirement, see decision (2). Probe real capabilities like `bluetooth_transport.dart` does with
`BleCapabilities` / `getCapabilities`, not just a platform string.

Discovery requirement: the transport must resolve a **paired `peerId`** to a concrete connection.
Reuse the proven BLE approach — advertise an identity characteristic / service record carrying
`deviceId`, scan, read it, match. See `bluetooth_transport.dart:_findDevice` and `_identityValue`.

---

## 2. Two-tier architecture — read before coding

Split responsibilities; do not make each radio do everything (that is why BLE is slow):

- **Discovery / signaling tier** (cheap, low bandwidth): BLE, NFC, mDNS — find the peer and exchange
  *how to connect*.
- **Bulk data tier** (fast): Wi-Fi Direct, Wi-Fi Aware, Multipeer, soft-AP, USB — carry the bytes.

The win pattern: **discover over BLE → upgrade to a fast Wi-Fi path for transfer.**

### 2.1 Crucial simplification: "IP-yielding" vs "message-stream" transports

| Transport | What it gives you | How to build the `PeerLink` |
|---|---|---|
| Wi-Fi Direct | a usable IP interface + peer IP (group owner) | **Reuse `DirectTcpTransport` / `TcpPeerLink`** over that interface — open a socket to the peer IP. Almost no new link code. |
| Wi-Fi Aware | an IP socket on the NAN data path | same — reuse `TcpPeerLink` over the granted socket. |
| Soft-AP / hotspot | a normal LAN once peers join | **Reuse the existing LAN + TCP + mDNS path unchanged.** Mostly a "bring the interface up" + UX problem. |
| USB / Ethernet | a normal IP interface | **Already works** with the existing LAN path. Doc + UX only. |
| MultipeerConnectivity | a message/stream session (no socket) | Write a `PeerLink` adapter with framing, like `_CentralBleLink` in `bluetooth_transport.dart`. |
| NFC | a one-shot byte exchange | Not a `PeerLink` at all — pairing/handoff only (see §6). |

**Implication:** Wi-Fi Direct / Aware / soft-AP / USB are mostly *interface bring-up + discovery*;
once an IP path exists, hand the socket to the existing TCP link. Only Multipeer needs a fresh
`PeerLink` adapter (model it on BLE). Budget your effort accordingly.

---

## 3. Wiring points in `SyncService` (`lib/sync/sync_service.dart`)

For each new transport, replicate exactly what `bluetooth` already does:

1. **Field** (near `:83`):
   ```dart
   late final WifiDirectTransport _wifiDirect =
       WifiDirectTransport(deviceId: identity.id, deviceName: deviceName);
   ```
2. **Start block in `start()`** (near `:141`, guarded by a new config flag):
   ```dart
   if (config.wifiDirectDiscovery) {
     try {
       await _wifiDirect.start();
       _subscriptions.add(_wifiDirect.incoming.listen(_acceptWifiDirect));
     } on Object catch (error) { _log('wifiDirect failed: $error'); }
   }
   ```
3. **`_acceptXxx` handler** — copy `_acceptBluetooth` (`:655`) verbatim, swapping the transport kind.
   It checks `_syncActive`, folder/peer existence, `peerIds.contains`, the `_active` dedupe key, then
   calls `_runLink(...)`.
4. **Outbound candidate in `_transportCandidates`** (`:725`) — add a `yield SyncTransportCandidate(...)`
   block with the right `priority` and `available` flag, calling `_xxx.open(peerId, folderId)`.
   Fire the `SyncEventKind.connecting` event like the others.
5. **Teardown in `stop()`** (`:831`): `await _wifiDirect.stop();`.

### 3.1 Transport registry — `lib/transport/sync_transport.dart`

Extend the enum and both switch arms:
```dart
enum SyncTransportKind { directTcp, localNetwork, wifiDirect, multipeer, bluetooth }
// id: 'tcp' | 'lan' | 'wifi-direct' | 'multipeer' | 'bluetooth'
// label: 'TCP' | 'Local network' | 'Wi-Fi Direct' | 'Multipeer' | 'Bluetooth'
```

### 3.2 Priority ordering (lower = tried first)

`SyncTransportCoordinator.open` sorts candidates by `priority` ascending and skips
unavailable / in-cooldown ones (backoff 5/15/30/60s). Current: directTcp=5, localNetwork=10,
bluetooth=20. Insert the fast offline paths **between LAN and BLE**, so BLE stays the last resort:

| Transport | priority | rationale |
|---|---|---|
| directTcp | 5 | fastest, needs known LAN address |
| localNetwork (WebRTC) | 10 | works across NAT when online |
| wifiDirect | 12 | fast, offline, no AP |
| multipeer | 13 | fast, offline, Apple platforms |
| (soft-AP feeds directTcp, no new kind) | — | becomes a `directTcp` candidate once the interface is up |
| bluetooth | 20 | slow, always-available last resort |

Only one of wifiDirect/multipeer is `available: true` on a given platform — keep both registered; the
`available` flag + platform check gates them.

---

## 4. Config flags — `lib/core/config.dart`

Mirror `bluetoothDiscovery`'s plumbing: add each new flag to the constructor, the field list,
`copyWith`, `toJson`, and `fromJson`. Suggested flags: `wifiDirectDiscovery`, `multipeerDiscovery`,
`hotspotFallback`, `nfcPairing`, `wifiAwareDiscovery`.

> **Decision (2): defaults are `false` (off).** New offline transports ship opt-in — constructor
> default `false`, `fromJson` `?? false`. The user turns them on per device. (Existing BLE/LAN/DHT
> flags keep their current `true` defaults; only the *new* transports default off.)

---

## 5. UI surface

### 5.1 Capability-gated visibility — decision (2), hard requirement

A toggle for an unsupported technology must **not exist at all** — not a disabled/greyed row, but
**absent**. If the device has no NFC chip, the NFC setting is simply not rendered. Drive this from
`XxxTransport.isSupported()` (§1.3): the settings screen `await`s the probe (cache the result in a
provider) and conditionally omits the row. Same gate guards `start()` in `SyncService` — never start
a transport the device can't do, regardless of the persisted flag.

### 5.2 Toggles, i18n, icons

- **Settings toggles**: copy the existing Bluetooth toggle. i18n lives in `lib/i18n/en.i18n.yaml`
  and `lib/i18n/ru.i18n.yaml` (`settings.bluetoothTitle` / `bluetoothSubtitle`,
  `activity.transportBluetooth`). Add parallel keys for each transport in **both** locale files.
- **Activity screen**: `lib/ui/screens/activity_screen.dart` maps a transport `id` → label/icon
  (around `:246`, `:253`, `:428`). Add `'wifi-direct' => Icons.wifi_tethering_rounded`,
  `'multipeer' => Icons.devices_rounded`, etc. Use M3 rounded icons and `context.colors.*` only.
- Remember the layout rule: side-rail ≥720 (no full-width AppBar), bottom NavigationBar <720.

---

## 6. NFC — pairing handoff only (not a `PeerLink`)

NFC does **not** carry sync. It replaces the camera step of QR pairing: tap to exchange the same
payload QR carries today (Device ID + swarm secret / pairing code). Integrate at the pairing layer
next to `pairViaCode` / `pairAt` (`sync_service.dart:347,366`) and `lib/transport/pairing_code.dart`,
**not** in `_transportCandidates`. Suggested package: `nfc_manager`. Encode the existing pairing
payload; on read, route into the same `pairViaCode` flow.

---

## 7. Package & platform notes per transport

Pick maintained packages; if none is solid, write a thin **Kotlin/Swift platform channel** (allowed).
Verify on pub.dev at implementation time — maturity shifts.

### 7.1 Wi-Fi Direct (Android primary)
- Package candidates: `flutter_p2p_connection`, or `flutter_nearby_connections` (also covers iOS
  Multipeer — see 7.2), or a Kotlin channel over `WifiP2pManager`.
- Flow: discover peers → form group → obtain group-owner IP → **open a TCP socket and reuse
  `TcpPeerLink`**. Match the paired `peerId` via the advertised service record.
- Android manifest: `ACCESS_FINE_LOCATION` (pre-13), `NEARBY_WIFI_DEVICES` (13+, `neverForLocation`),
  `ACCESS_WIFI_STATE`, `CHANGE_WIFI_STATE`. Request runtime perms (mirror BLE's `requestPermissions`).
- Desktop: Linux/Windows Wi-Fi Direct support is uneven — gate `available` by platform; prefer soft-AP
  there.

### 7.2 MultipeerConnectivity (iOS + macOS)
- Apple framework; no good pure-Dart package. Use `flutter_nearby_connections` (wraps Multipeer on
  Apple + Nearby on Android) **or** a Swift platform channel over `MCSession` / `MCNearbyServiceAdvertiser`
  / `MCNearbyServiceBrowser`.
- It yields a **message session**, not a socket → build a `PeerLink` adapter with chunk framing like
  `_CentralBleLink` / `_BleFramer` in `bluetooth_transport.dart`.
- Info.plist: `NSLocalNetworkUsageDescription`, `NSBonjourServices` (declare your service type, e.g.
  `_meshmarket._tcp`), `NSBluetoothAlwaysUsageDescription`.

### 7.3 Soft-AP / local hotspot
- Android: `WifiManager.LocalOnlyHotspot` via Kotlin channel (no root). Peers join → existing
  mDNS + `DirectTcpTransport` path works unchanged. This is mostly UX: show SSID/passphrase (or
  drive it via the NFC/QR handoff) and a "create hotspot" action.
- Desktop: rely on OS hotspot; document the manual steps. No new transport kind — it becomes a
  `directTcp` candidate once the shared LAN exists.

### 7.4 USB / Ethernet
- Already works: any USB-tether or wired interface gives IP → LAN path syncs. **Documentation + a UX
  hint only.** No code unless you add interface detection to nudge the user.

### 7.5 Wi-Fi Aware (NAN) — lower priority
- Android 8+ `WifiAwareManager` via Kotlin channel (no mature Flutter package). Serverless publish/
  subscribe + a data path socket → reuse `TcpPeerLink`. iOS has no public equivalent (Multipeer covers it).
- Implement only after Wi-Fi Direct ships; it is the "nicer but less supported" sibling.

---

## 8. Testing

- **Engine-level**: `dart test`. Transports are not unit-testable against real radios in CI. Add a
  loopback/fake `PeerLink` pair (two in-memory `StreamController`s wired head-to-head) to exercise
  `_runLink` / `SyncEngine` with each new `SyncTransportKind`. Mirror any existing transport tests.
- **Coordinator**: unit-test that new candidates sort/cooldown correctly in `SyncTransportCoordinator`
  (it takes an injectable `clock` — use it).
- **Radio paths**: manual device matrix only. Document a checklist: Android↔Android (Wi-Fi Direct),
  iPhone↔Mac (Multipeer), cross-platform via soft-AP, NFC tap-to-pair. Verify **all radios off except
  the one under test** to prove true offline.
- Run `dart analyze` clean before finishing. Keep every new file ≤300 lines.

---

## 9. Suggested phasing (each phase = independently shippable)

- **Phase 0 — plumbing**: add the enum kinds, config flags, i18n keys, activity-screen icons, and a
  reusable "bring up IP interface then reuse `TcpPeerLink`" helper. No behavior change yet.
- **Phase 1 — Wi-Fi Direct (Android)**: highest value; closes "BLE too slow." Reuse `TcpPeerLink`.
- **Phase 2 — MultipeerConnectivity (Apple)**: `PeerLink` adapter with framing; covers iOS/macOS.
- **Phase 3 — Soft-AP fallback**: UX + `LocalOnlyHotspot`; reuse LAN path.
- **Phase 4 — NFC pairing handoff**: pairing layer only.
- **Phase 5 — Wi-Fi Aware**: Android, after Phase 1.
- **Optional — Nearby Connections**: only if the Google-SDK dependency is acceptable; keep it off by default.

## 10. Definition of done (per transport)

- [ ] `XxxTransport` + `XxxIncomingLink` following the `tcp_transport.dart` shape, ≤300 lines.
- [ ] Resolves a paired `peerId` to a connection via an advertised identity (no central directory).
- [ ] Registered: `SyncTransportKind` enum + id/label, candidate in `_transportCandidates` with a
      priority from §3.2, `_acceptXxx` handler, field + `start()`/`stop()` wiring.
- [ ] Config flag (default **false**, user-enableable) across ctor/copyWith/toJson/fromJson.
- [ ] `isSupported()` capability probe; Settings row **hidden** (not disabled) when unsupported, and
      `start()` skips unsupported transports even if the flag is on.
- [ ] Settings toggle + activity icon/label, i18n in **both** `en` and `ru`.
- [ ] Platform permissions declared (Android manifest / iOS+macOS Info.plist & entitlements).
- [ ] Inherits the folder cipher via `_runLink` (no transport-level crypto added).
- [ ] `dart analyze` clean; loopback test exercises the new kind; manual radio check documented.

## 11. Decisions (resolved with the maintainer)

1. **Nearby Connections — do NOT implement (not even default-off, for now).** It depends on Google
   Play Services, so it fails on de-Googled ROMs (GrapheneOS, /e/OS, GMS-less devices) that overlap
   heavily with this project's audience; it is closed-source (undercuts the "auditable, no server of
   ours" pitch); and its core is C++. Implement the discrete transports (Wi-Fi Direct + Multipeer +
   BLE) instead. If ever revisited, it must be a separate opt-in build flavor, off by default, GMS-only.
2. **New transport flags default to `false` (off), opt-in.** AND visibility is capability-gated: if the
   hardware/OS can't do a transport, its Settings row is **absent**, not disabled (§5.1, §1.3).
3. **Native Kotlin/Swift bridges are approved.** Prefer a maintained Flutter package; fall back to a
   platform channel in Kotlin (Android) / Swift (Apple) where no solid package exists. (Never C/C++.)
4. **Priority ordering confirmed (§3.2):** Wi-Fi Direct / Multipeer rank **above** BLE and **below**
   LAN/WebRTC, so the fast offline paths beat BLE but never pre-empt an available IP path.
