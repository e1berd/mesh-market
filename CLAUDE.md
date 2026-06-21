# point-machine

Serverless peer-to-peer file synchronizer — a Syncthing alternative. Files sync directly
between a user's own devices with **no server of ours anywhere**, including for discovery.

## Platforms
android, ios, linux, macos, windows. **Web is intentionally dropped** (browsers cannot do
UDP/DHT or true background work).

## Stack
- Flutter + `m3e_core` + `declar_ui`.
- Transport: WebRTC data channels (`flutter_webrtc`).
- Discovery: `multicast_dns` (LAN), `bittorrent_dht` (WAN), QR pairing (`mobile_scanner` / `qr_flutter`).
- Crypto: `cryptography` (Ed25519, X25519, XChaCha20-Poly1305).
- Storage/index: `dart:io` + `sembast`. State: `flutter_riverpod`.
- Background: `flutter_background_service`, `workmanager`, `nativeapi`.

## Cardinal rule
**Material 3 Expressive, latest spec, everywhere.** Every screen, component, motion, shape,
and color follows M3 Expressive. Use `m3e_core` components and M3 `ColorScheme` roles
(`context.colors.*`) — never hard-coded colors.

It must read as *visibly Expressive*, not plain Material 3: expressive shapes (large/varied
corner radii ~28px, stadium buttons), bold and large emphasized type, spring motion via
`m3e_core`, and generous use of container color roles. Plain M3 defaults are not enough.

## UI conventions
- **Side-rail layout (width ≥ 720):** `NavigationRail` + a `VerticalDivider` must span the
  **full window height**. Do not put a full-width `AppBar` above them — the screen title
  lives *inside* the content pane (right of the divider). Otherwise the divider stops below
  the bar, which is wrong.
- **Compact layout (width < 720):** top `AppBar` + bottom `NavigationBar` is correct.
- Theme tokens (shapes, type, nav indicators) live in `lib/ui/theme.dart` via `pointTheme`.

## Coding rules
- **No explanatory comments.** Code must be self-documenting through naming and structure.
- Code must be easy for a human to read.
- **Max 300 lines per file**; ideally everything fits in 1–2 screens of height.
- **Dark / light / system** theme support, switchable by the user.
- **Use dot shorthands** wherever the language allows (`.system`, `.filled`, `.center`)
  instead of the fully-qualified form.
- Backend / native code must **not** be C/C++. All our code is pure Dart.

## Architecture (no server, ever)
WebRTC needs a rendezvous; we replace the central signaling server with three serverless paths:
1. **LAN** — mDNS multicast, connect with host candidates. Zero infrastructure.
2. **WAN** — BitTorrent Mainline DHT discovery under an infohash derived from the folder
   swarm secret; SDP/ICE exchanged over the discovered transport, then a hole-punched DTLS
   data channel.
3. **Pairing / fallback** — QR exchange of device identity + swarm secret.

DHT bootstrap routers and optional STUN are public, dataless, replaceable, and **disableable**
(disabled ⇒ LAN + manual QR only). File bytes never touch any third party.

## Security
- Transit: WebRTC DTLS 1.3.
- E2E: every block sealed with XChaCha20-Poly1305 under the per-folder key before sending.
- At rest: blocks stored encrypted on disk.
- Identity: Ed25519 device keys; only explicitly paired Device IDs connect.
- **STUN/TURN endpoints are user-configurable in Settings**, with a disable option.

## Package gotchas
- `declar_ui` re-exports `package:flutter/material.dart` but **hides** the widgets it wraps
  (`Text`, `Column`, `Row`, `Container`, `SizedBox`, `Scaffold`, `MaterialApp`, `Card`,
  `ListView`, `Stack`, `Icon`, `Image`, `TextField`, `Wrap`, `SafeArea`, `CustomScrollView`).
  In UI files import **`declar_ui` only** (plus `m3e_core`, riverpod, local files) — do **not**
  also import `flutter/material`, or those names become ambiguous.
- declar wrappers are chainable: `Scaffold().body(x).appBar(y)`, `MaterialApp().theme(t).home(h)`,
  `Column(children: [...]).spacing(8)`, `Text('x').size(16).weight(.bold)`, plus widget
  extensions `.padding(...)`, `.onTap(...)`, `.expanded()`, `.center()`.
- Context extensions: `context.colors`, `context.theme`, `context.textTheme`, `context.width`,
  `context.push(widget)`, `context.showSnackBar(...)`.
- m3e_core public widgets: `M3EButton` (`.icon` factory), `M3ECard`, `M3ECardList`,
  `M3ECardColumn`, `M3EDismissibleCardList`, `M3EExpandableItem`, `M3EShape`,
  `M3EToggleButton(Group)`, `M3ESplitButton`. Enums: `M3EButtonStyle`, `M3EButtonSize`,
  `M3EButtonShape`.
- Need a material `TextField` (declar hides it)? Build that piece in a file that imports
  `package:flutter/material.dart` only, with no declar import.

## Layout
`lib/core` models/config/identity · `lib/crypto` · `lib/storage` · `lib/sync` ·
`lib/transport` · `lib/platform` · `lib/state` providers · `lib/ui` screens & widgets.
