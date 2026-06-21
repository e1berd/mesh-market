import 'package:flutter/material.dart' show ThemeMode;

class IceServer {
  const IceServer({required this.url, this.username, this.credential});

  final String url;
  final String? username;
  final String? credential;

  bool get isTurn => url.startsWith('turn:') || url.startsWith('turns:');

  Map<String, dynamic> toWebRtc() => {
    'urls': url,
    if (username != null) 'username': username,
    if (credential != null) 'credential': credential,
  };
}

const defaultIceServers = [IceServer(url: 'stun:stun.l.google.com:19302')];

class AppConfig {
  const AppConfig({
    this.themeMode = .system,
    this.themeSchemeId = 'violet',
    this.iceServers = defaultIceServers,
    this.lanDiscovery = true,
    this.dhtDiscovery = true,
    this.bluetoothDiscovery = true,
    this.syncInBackground = true,
    this.syncNow = false,
    this.scheduleEnabled = false,
    this.scheduleStart = 720,
    this.scheduleEnd = 750,
  });

  final ThemeMode themeMode;
  final String themeSchemeId;
  final List<IceServer> iceServers;
  final bool lanDiscovery;
  final bool dhtDiscovery;
  final bool bluetoothDiscovery;
  final bool syncInBackground;
  final bool syncNow;
  final bool scheduleEnabled;
  final int scheduleStart;
  final int scheduleEnd;

  AppConfig copyWith({
    ThemeMode? themeMode,
    String? themeSchemeId,
    List<IceServer>? iceServers,
    bool? lanDiscovery,
    bool? dhtDiscovery,
    bool? bluetoothDiscovery,
    bool? syncInBackground,
    bool? syncNow,
    bool? scheduleEnabled,
    int? scheduleStart,
    int? scheduleEnd,
  }) => AppConfig(
    themeMode: themeMode ?? this.themeMode,
    themeSchemeId: themeSchemeId ?? this.themeSchemeId,
    iceServers: iceServers ?? this.iceServers,
    lanDiscovery: lanDiscovery ?? this.lanDiscovery,
    dhtDiscovery: dhtDiscovery ?? this.dhtDiscovery,
    bluetoothDiscovery: bluetoothDiscovery ?? this.bluetoothDiscovery,
    syncInBackground: syncInBackground ?? this.syncInBackground,
    syncNow: syncNow ?? this.syncNow,
    scheduleEnabled: scheduleEnabled ?? this.scheduleEnabled,
    scheduleStart: scheduleStart ?? this.scheduleStart,
    scheduleEnd: scheduleEnd ?? this.scheduleEnd,
  );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.index,
    'themeSchemeId': themeSchemeId,
    'iceServers': iceServers
        .map(
          (s) => {
            'url': s.url,
            if (s.username != null) 'username': s.username,
            if (s.credential != null) 'credential': s.credential,
          },
        )
        .toList(),
    'lanDiscovery': lanDiscovery,
    'dhtDiscovery': dhtDiscovery,
    'bluetoothDiscovery': bluetoothDiscovery,
    'syncInBackground': syncInBackground,
    'syncNow': syncNow,
    'scheduleEnabled': scheduleEnabled,
    'scheduleStart': scheduleStart,
    'scheduleEnd': scheduleEnd,
  };

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
    themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
    themeSchemeId: json['themeSchemeId'] as String? ?? 'violet',
    iceServers:
        (json['iceServers'] as List<dynamic>?)
            ?.map(
              (s) => IceServer(
                url: s['url'] as String,
                username: s['username'] as String?,
                credential: s['credential'] as String?,
              ),
            )
            .toList() ??
        defaultIceServers,
    lanDiscovery: json['lanDiscovery'] as bool? ?? true,
    dhtDiscovery: json['dhtDiscovery'] as bool? ?? true,
    bluetoothDiscovery: json['bluetoothDiscovery'] as bool? ?? true,
    syncInBackground: json['syncInBackground'] as bool? ?? true,
    syncNow: json['syncNow'] as bool? ?? false,
    scheduleEnabled: json['scheduleEnabled'] as bool? ?? false,
    scheduleStart: json['scheduleStart'] as int? ?? 720,
    scheduleEnd: json['scheduleEnd'] as int? ?? 750,
  );
}
