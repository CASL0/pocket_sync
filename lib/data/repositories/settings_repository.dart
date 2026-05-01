import 'package:flutter/material.dart' show ThemeMode;
import 'package:pocket_sync/domain/models/app_preferences.dart';
import 'package:pocket_sync/domain/models/sync_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  SettingsRepository({required SharedPreferences prefs}) : _prefs = prefs;

  static const _keyWifiOnly = 'sync.wifi_only';
  static const _keyChargingOnly = 'sync.charging_only';
  static const _keyBackgroundSync = 'sync.background_sync';
  static const _keyThemeMode = 'app.theme_mode';
  static const _keyLanguage = 'app.language';

  final SharedPreferences _prefs;

  SyncSettings load() {
    return SyncSettings(
      wifiOnly: _prefs.getBool(_keyWifiOnly) ?? false,
      chargingOnly: _prefs.getBool(_keyChargingOnly) ?? false,
      backgroundSync: _prefs.getBool(_keyBackgroundSync) ?? false,
    );
  }

  Future<void> save(SyncSettings settings) async {
    await Future.wait([
      _prefs.setBool(_keyWifiOnly, settings.wifiOnly),
      _prefs.setBool(_keyChargingOnly, settings.chargingOnly),
      _prefs.setBool(_keyBackgroundSync, settings.backgroundSync),
    ]);
  }

  AppPreferences loadPreferences() {
    return AppPreferences(
      themeMode: _parseThemeMode(_prefs.getString(_keyThemeMode)),
      language: _parseLanguage(_prefs.getString(_keyLanguage)),
    );
  }

  Future<void> savePreferences(AppPreferences preferences) async {
    await Future.wait([
      _prefs.setString(_keyThemeMode, preferences.themeMode.name),
      _prefs.setString(_keyLanguage, preferences.language.name),
    ]);
  }

  static ThemeMode _parseThemeMode(String? name) {
    return ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  static AppLanguage _parseLanguage(String? name) {
    return AppLanguage.values.firstWhere(
      (l) => l.name == name,
      orElse: () => AppLanguage.system,
    );
  }
}
