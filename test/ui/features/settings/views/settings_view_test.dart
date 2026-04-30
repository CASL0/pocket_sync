import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pocket_sync/data/repositories/settings_repository.dart';
import 'package:pocket_sync/domain/models/sync_settings.dart';
import 'package:pocket_sync/ui/features/settings/view_models/settings_view_model.dart';
import 'package:pocket_sync/ui/features/settings/views/settings_view.dart';
import 'package:provider/provider.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({SyncSettings initial = const SyncSettings()})
    : _settings = initial;

  SyncSettings _settings;

  @override
  SyncSettings load() => _settings;

  @override
  Future<void> save(SyncSettings settings) async {
    _settings = settings;
  }
}

Widget _buildHarness({required SettingsViewModel vm}) {
  return ChangeNotifierProvider<SettingsViewModel>.value(
    value: vm,
    child: const MaterialApp(home: SettingsView()),
  );
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'pocket_sync',
      packageName: 'com.example.pocket_sync',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  group('SettingsView', () {
    testWidgets('AppBarタイトルとセクション見出しが表示される', (tester) async {
      final vm = SettingsViewModel(
        repository: _FakeSettingsRepository(),
      );

      await tester.pumpWidget(_buildHarness(vm: vm));
      await tester.pumpAndSettle();

      expect(find.text('設定'), findsOneWidget);
      expect(find.text('同期'), findsOneWidget);
      expect(find.text('アプリについて'), findsOneWidget);
    });

    testWidgets('3つの同期トグルが表示される', (tester) async {
      final vm = SettingsViewModel(
        repository: _FakeSettingsRepository(),
      );

      await tester.pumpWidget(_buildHarness(vm: vm));
      await tester.pumpAndSettle();

      expect(find.text('Wi-Fi接続時のみ同期'), findsOneWidget);
      expect(find.text('充電中のみ同期'), findsOneWidget);
      expect(find.text('バックグラウンド同期'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(3));
    });

    testWidgets('初期状態のトグルはVMの値を反映する', (tester) async {
      final vm = SettingsViewModel(
        repository: _FakeSettingsRepository(
          initial: const SyncSettings(wifiOnly: true),
        ),
      );

      await tester.pumpWidget(_buildHarness(vm: vm));
      await tester.pumpAndSettle();

      final wifiTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Wi-Fi接続時のみ同期'),
      );
      expect(wifiTile.value, isTrue);

      final chargingTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, '充電中のみ同期'),
      );
      expect(chargingTile.value, isFalse);
    });

    testWidgets('Wi-FiトグルをタップするとVMが更新されUIに反映される', (tester) async {
      final vm = SettingsViewModel(
        repository: _FakeSettingsRepository(),
      );

      await tester.pumpWidget(_buildHarness(vm: vm));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Wi-Fi接続時のみ同期'),
      );
      await tester.pumpAndSettle();

      expect(vm.settings.wifiOnly, isTrue);
      final wifiTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Wi-Fi接続時のみ同期'),
      );
      expect(wifiTile.value, isTrue);
    });

    testWidgets('バージョン情報がpackage_info_plusから取得して表示される', (tester) async {
      final vm = SettingsViewModel(
        repository: _FakeSettingsRepository(),
      );

      await tester.pumpWidget(_buildHarness(vm: vm));
      await tester.pumpAndSettle();

      expect(find.text('バージョン'), findsOneWidget);
      expect(find.text('1.2.3'), findsOneWidget);
    });

    testWidgets('ライセンスをタップするとshowLicensePageが開く', (tester) async {
      final vm = SettingsViewModel(
        repository: _FakeSettingsRepository(),
      );

      await tester.pumpWidget(_buildHarness(vm: vm));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ライセンス'));
      await tester.pumpAndSettle();

      // showLicensePageが開くと"ライセンス"を含むタイトルや関連UIが表示される
      // 実装依存なのでLicensePageの存在を確認
      expect(find.byType(LicensePage), findsOneWidget);
    });
  });
}
