import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:pocket_sync/data/repositories/settings_repository.dart';
import 'package:pocket_sync/domain/models/app_preferences.dart';
import 'package:pocket_sync/domain/models/sync_settings.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required SettingsRepository repository})
    : _repository = repository,
      _settings = repository.load(),
      _preferences = repository.loadPreferences();

  final SettingsRepository _repository;
  SyncSettings _settings;
  AppPreferences _preferences;

  SyncSettings get settings => _settings;
  AppPreferences get preferences => _preferences;

  Future<void> setWifiOnly({required bool value}) =>
      _updateSync((s) => s.copyWith(wifiOnly: value));

  Future<void> setChargingOnly({required bool value}) =>
      _updateSync((s) => s.copyWith(chargingOnly: value));

  Future<void> setBackgroundSync({required bool value}) =>
      _updateSync((s) => s.copyWith(backgroundSync: value));

  Future<void> setThemeMode(ThemeMode mode) =>
      _updatePreferences((p) => p.copyWith(themeMode: mode));

  Future<void> setLanguage(AppLanguage language) =>
      _updatePreferences((p) => p.copyWith(language: language));

  Future<void> _updateSync(SyncSettings Function(SyncSettings) updater) async {
    final previous = _settings;
    _settings = updater(_settings);
    notifyListeners();
    try {
      await _repository.save(_settings);
    } catch (_) {
      _settings = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _updatePreferences(
    AppPreferences Function(AppPreferences) updater,
  ) async {
    final previous = _preferences;
    _preferences = updater(_preferences);
    notifyListeners();
    try {
      await _repository.savePreferences(_preferences);
    } catch (_) {
      _preferences = previous;
      notifyListeners();
      rethrow;
    }
  }
}
