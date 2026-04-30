import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/data/repositories/settings_repository.dart';
import 'package:pocket_sync/domain/models/sync_settings.dart';
import 'package:pocket_sync/ui/features/settings/view_models/settings_view_model.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({SyncSettings initial = const SyncSettings()})
    : _settings = initial;

  SyncSettings _settings;
  SyncSettings? lastSaved;
  int saveCallCount = 0;
  bool throwOnNextSave = false;

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
  });
}
