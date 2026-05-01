import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/data/repositories/settings_repository.dart';
import 'package:pocket_sync/domain/models/app_preferences.dart';
import 'package:pocket_sync/domain/models/sync_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsRepository', () {
    late SharedPreferences prefs;
    late SettingsRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = SettingsRepository(prefs: prefs);
    });

    test('未設定状態のloadは全フラグfalseを返す', () {
      final settings = repository.load();

      expect(settings.wifiOnly, isFalse);
      expect(settings.chargingOnly, isFalse);
      expect(settings.backgroundSync, isFalse);
    });

    test('saveした値がloadで復元される', () async {
      const target = SyncSettings(
        wifiOnly: true,
        backgroundSync: true,
      );

      await repository.save(target);
      final loaded = repository.load();

      expect(loaded, equals(target));
    });

    test('永続化キーがSharedPreferencesに書き込まれる', () async {
      const target = SyncSettings(wifiOnly: true);

      await repository.save(target);

      expect(prefs.getBool('sync.wifi_only'), isTrue);
      expect(prefs.getBool('sync.charging_only'), isFalse);
      expect(prefs.getBool('sync.background_sync'), isFalse);
    });

    test('既存値を上書きできる', () async {
      await repository.save(const SyncSettings(wifiOnly: true));
      await repository.save(const SyncSettings(chargingOnly: true));

      final loaded = repository.load();

      expect(loaded.wifiOnly, isFalse);
      expect(loaded.chargingOnly, isTrue);
    });

    test('未設定状態のloadPreferencesはsystemデフォルトを返す', () {
      final prefs = repository.loadPreferences();

      expect(prefs.themeMode, ThemeMode.system);
      expect(prefs.language, AppLanguage.system);
    });

    test('savePreferencesした値がloadPreferencesで復元される', () async {
      const target = AppPreferences(
        themeMode: ThemeMode.dark,
        language: AppLanguage.en,
      );

      await repository.savePreferences(target);
      final loaded = repository.loadPreferences();

      expect(loaded, equals(target));
    });

    test('AppPreferencesはenum名で永続化される', () async {
      const target = AppPreferences(
        themeMode: ThemeMode.light,
        language: AppLanguage.ja,
      );

      await repository.savePreferences(target);

      expect(prefs.getString('app.theme_mode'), 'light');
      expect(prefs.getString('app.language'), 'ja');
    });

    test('未知の永続化値はデフォルトにフォールバックする', () async {
      await prefs.setString('app.theme_mode', 'unknown');
      await prefs.setString('app.language', 'fr');

      final loaded = repository.loadPreferences();

      expect(loaded.themeMode, ThemeMode.system);
      expect(loaded.language, AppLanguage.system);
    });
  });
}
