![Mesh Market devices screen](docs/hero_banner.png)

# Mesh Market

Mesh Market syncs folders directly between a user's own devices with no central server. On a local network, devices find each other over mDNS multicast. Over the internet, peers are located through **BitTorrent Mainline DHT** using an infohash derived from the folder swarm secret; SDP and ICE candidates are then exchanged over that DHT transport to establish a hole-punched WebRTC data channel. Every file block is encrypted with XChaCha20-Poly1305 before leaving the device.

`Flutter` · `Android` · `iOS` · `Linux` · `macOS` · `Windows`

## What It Does

- Pairs trusted devices by LAN discovery, QR/manual payload exchange, or a shared remote pairing code.
- Syncs folders between paired devices.
- Transfers changed file blocks instead of resending whole files.
- Detects concurrent edits and keeps conflict copies instead of overwriting local changes silently.
- Supports direct LAN transport, WebRTC data channels, DHT-based peer discovery, and Bluetooth fallback.
- Runs in the background on supported platforms through platform-specific services or tray integration.

## Security Model

- Device identity is based on local public/private key pairs.
- Only explicitly paired devices are accepted.
- File blocks are encrypted with XChaCha20-Poly1305 before they leave the device.
- Folder keys are derived per device pair using X25519 and HKDF-SHA256.
- DHT and STUN are used only for discovery/connectivity. File contents do not pass through them.

## Minimum Requirements

Runtime:

- Android: Flutter-supported Android device with storage access; Bluetooth features require Bluetooth LE support and runtime permissions.
- iOS: iOS 13.0 or newer.
- macOS: macOS 10.15 or newer.
- Linux: 64-bit Linux desktop with GTK, network access, and file-system permissions for synced folders.
- Windows: 64-bit Windows desktop supported by Flutter.
- Network: local network access for LAN sync; internet access is required for DHT/STUN-assisted remote discovery.
- Storage: enough free disk space for the selected synced folders and local metadata.

Development:

- `just` 1.45.0 or newer for project task shortcuts.
- Flutter SDK 3.44.0 or newer.
- Dart SDK 3.12.2 or newer, below 4.0.0.
- Java 17 for Android builds.
- Android Studio or Android command-line tools with Android SDK 36 for Android builds.
- Xcode with iOS 13.0 and macOS 10.15 deployment target support for iOS and macOS builds.
- CMake 3.14 or newer, Ninja, GTK 3 development packages, pkg-config, and a C++ toolchain for Linux builds.
- Visual Studio with Desktop development with C++ and CMake 3.14 or newer for Windows builds.

## Build

Install dependencies:

```sh
flutter pub get
```

Run analysis:

```sh
dart analyze
```

Run tests:

```sh
NO_PROXY=localhost,127.0.0.1,::1 no_proxy=localhost,127.0.0.1,::1 flutter test
```

Build examples:

```sh
flutter build apk --release
flutter build linux --release
flutter build macos --release
flutter build windows --release
```

## Current Limitations

- General WAN sync depends on peer reachability and NAT traversal conditions.
- iOS background execution is constrained by the operating system.
- Some mobile folder selection behavior is limited by platform storage APIs.

See [docs/en/architecture.md](docs/en/architecture.md) for implementation details.