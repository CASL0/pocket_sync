import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/data/repositories/settings_repository.dart';
import 'package:pocket_sync/domain/models/app_preferences.dart';
import 'package:pocket_sync/domain/models/sync_settings.dart';
import 'package:pocket_sync/ui/features/settings/view_models/settings_view_model.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({
    SyncSettings initial = const SyncSettings(),
    AppPreferences initialPreferences = const AppPreferences(),
  }) : _settings = initial,
       _preferences = initialPreferences;

  SyncSettings _settings;
  AppPreferences _preferences;
  SyncSettings? lastSaved;
  AppPreferences? lastSavedPreferences;
  int saveCallCount = 0;
  int savePreferencesCallCount = 0;
  bool throwOnNextSave = false;
  bool throwOnNextSavePreferences = false;

  @override
  SyncSettings load() => _settings;

  @override
  Future<void> save(SyncSettings settings) async {
    saveCallCount++;
    if (throwOnNextSave) {
      throwOnNextSave = false;
      throw Exception('save failed');
    }
    lastSaved = settings;
    _settings = settings;
  }

  @override
  AppPreferences loadPreferences() => _preferences;

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    savePreferencesCallCount++;
    if (throwOnNextSavePreferences) {
      throwOnNextSavePreferences = false;
      throw Exception('savePreferences failed');
    }
    lastSavedPreferences = preferences;
    _preferences = preferences;
  }
}

void main() {
  group('SettingsViewModel', () {
    test('初期化時にrepositoryからloadした値で開始する', () {
      final repository = _FakeSettingsRepository(
        initial: const SyncSettings(wifiOnly: true),
      );

      final vm = SettingsViewModel(repository: repository);

      expect(vm.settings.wifiOnly, isTrue);
      expect(vm.settings.chargingOnly, isFalse);
    });

    test('setWifiOnlyで値が更新されrepositoryに保存される', () async {
      final repository = _FakeSettingsRepository();
      final vm = SettingsViewModel(repository: repository);

      await vm.setWifiOnly(value: true);

      expect(vm.settings.wifiOnly, isTrue);
      expect(repository.lastSaved?.wifiOnly, isTrue);
    });

    test('setChargingOnlyとsetBackgroundSyncも独立して動作する', () async {
      final repository = _FakeSettingsRepository();
      final vm = SettingsViewModel(repository: repository);

      await vm.setChargingOnly(value: true);
      await vm.setBackgroundSync(value: true);

      expect(vm.settings.chargingOnly, isTrue);
      expect(vm.settings.backgroundSync, isTrue);
      expect(vm.settings.wifiOnly, isFalse);
    });

    test('値変更時にnotifyListenersが呼ばれる', () async {
      final repository = _FakeSettingsRepository();
      final vm = SettingsViewModel(repository: repository);
      var notifyCount = 0;
      vm.addListener(() => notifyCount++);

      await vm.setWifiOnly(value: true);

      // 楽観更新で1回 + 永続化完了で何もしない設計なので最低1回
      expect(notifyCount, greaterThanOrEqualTo(1));
    });

    test('save失敗時は値が元に戻りnotifyListenersが再度呼ばれる', () async {
      final repository = _FakeSettingsRepository()..throwOnNextSave = true;
      final vm = SettingsViewModel(repository: repository);
      var notifyCount = 0;
      vm.addListener(() => notifyCount++);

      await expectLater(
        vm.setWifiOnly(value: true),
        throwsException,
      );

      expect(vm.settings.wifiOnly, isFalse);
      // 楽観更新(true) + ロールバック(false) で2回
      expect(notifyCount, equals(2));
    });

    test('初期化時にrepositoryからAppPreferencesも読み込む', () {
      final repository = _FakeSettingsRepository(
        initialPreferences: const AppPreferences(
          themeMode: ThemeMode.dark,
          language: AppLanguage.en,
        ),
      );

      final vm = SettingsViewModel(repository: repository);

      expect(vm.preferences.themeMode, ThemeMode.dark);
      expect(vm.preferences.language, AppLanguage.en);
    });

    test('setThemeModeで値が更新されrepositoryに保存される', () async {
      final repository = _FakeSettingsRepository();
      final vm = SettingsViewModel(repository: repository);

      await vm.setThemeMode(ThemeMode.dark);

      expect(vm.preferences.themeMode, ThemeMode.dark);
      expect(repository.lastSavedPreferences?.themeMode, ThemeMode.dark);
    });

    test('setLanguageで値が更新されrepositoryに保存される', () async {
      final repository = _FakeSettingsRepository();
      final vm = SettingsViewModel(repository: repository);

      await vm.setLanguage(AppLanguage.ja);

      expect(vm.preferences.language, AppLanguage.ja);
      expect(repository.lastSavedPreferences?.language, AppLanguage.ja);
    });

    test('savePreferences失敗時は値が元に戻る', () async {
      final repository = _FakeSettingsRepository()
        ..throwOnNextSavePreferences = true;
      final vm = SettingsViewModel(repository: repository);
      var notifyCount = 0;
      vm.addListener(() => notifyCount++);

      await expectLater(
        vm.setThemeMode(ThemeMode.dark),
        throwsException,
      );

      expect(vm.preferences.themeMode, ThemeMode.system);
      // 楽観更新 + ロールバック で2回
      expect(notifyCount, equals(2));
    });

    test('themeModeとlanguageは独立して保持される', () async {
      final repository = _FakeSettingsRepository();
      final vm = SettingsViewModel(repository: repository);

      await vm.setThemeMode(ThemeMode.light);
      await vm.setLanguage(AppLanguage.en);

      expect(vm.preferences.themeMode, ThemeMode.light);
      expect(vm.preferences.language, AppLanguage.en);
    });
  });
}
