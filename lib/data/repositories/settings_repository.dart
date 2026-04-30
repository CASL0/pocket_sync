import 'package:pocket_sync/domain/models/sync_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  SettingsRepository({required SharedPreferences prefs}) : _prefs = prefs;

  static const _keyWifiOnly = 'sync.wifi_only';
  static const _keyChargingOnly = 'sync.charging_only';
  static const _keyBackgroundSync = 'sync.background_sync';

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
}
