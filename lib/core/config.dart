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
    this.syncInBackground = true,
  });

  final ThemeMode themeMode;
  final String themeSchemeId;
  final List<IceServer> iceServers;
  final bool lanDiscovery;
  final bool dhtDiscovery;
  final bool syncInBackground;

  AppConfig copyWith({
    ThemeMode? themeMode,
    String? themeSchemeId,
    List<IceServer>? iceServers,
    bool? lanDiscovery,
    bool? dhtDiscovery,
    bool? syncInBackground,
  }) => AppConfig(
    themeMode: themeMode ?? this.themeMode,
    themeSchemeId: themeSchemeId ?? this.themeSchemeId,
    iceServers: iceServers ?? this.iceServers,
    lanDiscovery: lanDiscovery ?? this.lanDiscovery,
    dhtDiscovery: dhtDiscovery ?? this.dhtDiscovery,
    syncInBackground: syncInBackground ?? this.syncInBackground,
  );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.index,
    'themeSchemeId': themeSchemeId,
    'iceServers': iceServers
        .map((s) => {
          'url': s.url,
          if (s.username != null) 'username': s.username,
          if (s.credential != null) 'credential': s.credential,
        })
        .toList(),
    'lanDiscovery': lanDiscovery,
    'dhtDiscovery': dhtDiscovery,
    'syncInBackground': syncInBackground,
  };

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
    themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
    themeSchemeId: json['themeSchemeId'] as String? ?? 'violet',
    iceServers: (json['iceServers'] as List<dynamic>?)
            ?.map((s) => IceServer(
              url: s['url'] as String,
              username: s['username'] as String?,
              credential: s['credential'] as String?,
            ))
            .toList() ??
        defaultIceServers,
    lanDiscovery: json['lanDiscovery'] as bool? ?? true,
    dhtDiscovery: json['dhtDiscovery'] as bool? ?? true,
    syncInBackground: json['syncInBackground'] as bool? ?? true,
  );
}
