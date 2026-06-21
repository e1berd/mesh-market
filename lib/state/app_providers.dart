import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../i18n/strings.g.dart';

const _prefsKey = 'app_config';

SharedPreferences? _initialPrefs;
AppConfig? _initialConfig;

final configProvider = NotifierProvider<ConfigNotifier, AppConfig>(
  ConfigNotifier.new,
);

Future<AppConfig> loadInitialConfig() async {
  final prefs = await SharedPreferences.getInstance();
  final config = _readConfig(prefs);
  _initialPrefs = prefs;
  _initialConfig = config;
  await _applyLocale(config);
  return config;
}

class ConfigNotifier extends Notifier<AppConfig> {
  SharedPreferences? _prefs;

  @override
  AppConfig build() {
    final initial = _initialConfig;
    if (initial != null) {
      _prefs = _initialPrefs;
      return initial;
    }
    _load();
    return const AppConfig();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = _readConfig(_prefs!);
    await _applyLocale(state);
  }

  void setLocale(AppLocale locale) {
    LocaleSettings.setLocale(locale);
    state = state.copyWith(localeCode: locale.languageCode);
    _save();
  }

  Future<void> _save() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _save();
  }

  void setThemeScheme(String id) {
    state = state.copyWith(themeSchemeId: id);
    _save();
  }

  void toggleLanDiscovery(bool value) {
    state = state.copyWith(lanDiscovery: value);
    _save();
  }

  void toggleDhtDiscovery(bool value) {
    state = state.copyWith(dhtDiscovery: value);
    _save();
  }

  void toggleBluetoothDiscovery(bool value) {
    state = state.copyWith(bluetoothDiscovery: value);
    _save();
  }

  void toggleBackground(bool value) {
    state = state.copyWith(syncInBackground: value);
    _save();
  }

  void setSyncNow(bool value) {
    state = state.copyWith(syncNow: value);
    _save();
  }

  void setScheduleEnabled(bool value) {
    state = state.copyWith(scheduleEnabled: value);
    _save();
  }

  void setSchedule(int startMinutes, int endMinutes) {
    state = state.copyWith(
      scheduleStart: startMinutes,
      scheduleEnd: endMinutes,
    );
    _save();
  }

  void setActivityLogPath(String path) {
    state = state.copyWith(activityLogPath: path);
    _save();
  }

  void addIceServer(IceServer server) {
    state = state.copyWith(iceServers: [...state.iceServers, server]);
    _save();
  }

  void removeIceServer(int index) {
    state = state.copyWith(iceServers: [...state.iceServers]..removeAt(index));
    _save();
  }
}

AppConfig _readConfig(SharedPreferences prefs) {
  final json = prefs.getString(_prefsKey);
  if (json == null) return const AppConfig();
  return AppConfig.fromJson(
    Map<String, dynamic>.from(jsonDecode(json) as Map<String, dynamic>),
  );
}

Future<void> _applyLocale(AppConfig config) async {
  final code = config.localeCode;
  if (code != null) await LocaleSettings.setLocaleRaw(code);
}
