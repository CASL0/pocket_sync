import 'package:flutter/foundation.dart';
import 'package:pocket_sync/data/repositories/settings_repository.dart';
import 'package:pocket_sync/domain/models/sync_settings.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required SettingsRepository repository})
    : _repository = repository,
      _settings = repository.load();

  final SettingsRepository _repository;
  SyncSettings _settings;

  SyncSettings get settings => _settings;

  Future<void> setWifiOnly({required bool value}) =>
      _update((s) => s.copyWith(wifiOnly: value));

  Future<void> setChargingOnly({required bool value}) =>
      _update((s) => s.copyWith(chargingOnly: value));

  Future<void> setBackgroundSync({required bool value}) =>
      _update((s) => s.copyWith(backgroundSync: value));

  Future<void> _update(SyncSettings Function(SyncSettings) updater) async {
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
}
