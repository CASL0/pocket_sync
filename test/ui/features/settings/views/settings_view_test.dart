import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pocket_sync/data/repositories/aws_credentials_repository.dart';
import 'package:pocket_sync/data/repositories/settings_repository.dart';
import 'package:pocket_sync/domain/models/app_preferences.dart';
import 'package:pocket_sync/domain/models/aws_credentials.dart';
import 'package:pocket_sync/domain/models/sync_settings.dart';
import 'package:pocket_sync/l10n/app_localizations.dart';
import 'package:pocket_sync/ui/features/settings/view_models/aws_credentials_view_model.dart';
import 'package:pocket_sync/ui/features/settings/view_models/settings_view_model.dart';
import 'package:pocket_sync/ui/features/settings/views/settings_view.dart';
import 'package:provider/provider.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({
    SyncSettings initial = const SyncSettings(),
    AppPreferences initialPreferences = const AppPreferences(),
  }) : _settings = initial,
       _preferences = initialPreferences;

  SyncSettings _settings;
  AppPreferences _preferences;

  @override
  SyncSettings load() => _settings;

  @override
  Future<void> save(SyncSettings settings) async {
    _settings = settings;
  }

  @override
  AppPreferences loadPreferences() => _preferences;

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    _preferences = preferences;
  }
}

class _FakeAwsCredentialsRepository implements AwsCredentialsRepository {
  AwsCredentials _stored = AwsCredentials.empty;

  @override
  Future<AwsCredentials> load() async => _stored;

  @override
  Future<void> save(AwsCredentials creds) async => _stored = creds;

  @override
  Future<void> clear() async => _stored = AwsCredentials.empty;
}

Widget _buildHarness({required SettingsViewModel vm}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsViewModel>.value(value: vm),
      ChangeNotifierProvider<AwsCredentialsViewModel>(
        create: (_) => AwsCredentialsViewModel(
          repository: _FakeAwsCredentialsRepository(),
        ),
      ),
    ],
    child: const MaterialApp(
      locale: Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SettingsView(),
    ),
  );
}

/// AWS 認証情報セクションが入って画面が縦長になったため、
/// 既存テストでビューポート不足にならないよう物理サイズを拡張する。
/// 1080x3000 で全項目が見える想定。
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
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
      _useTallViewport(tester);
      final vm = SettingsViewModel(
        repository: _FakeSettingsRepository(),
      );

      await tester.pumpWidget(_buildHarness(vm: vm));
      await tester.pumpAndSettle();

      expect(find.text('設定'), findsOneWidget);
      expect(find.text('同期'), findsOneWidget);
      expect(find.text('AWS 認証情報'), findsOneWidget);
      expect(find.text('表示'), findsOneWidget);
      expect(find.text('言語'), findsOneWidget);
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

    testWidgets('テーマ項目の現在値がサブタイトルに表示される', (tester) async {
      _useTallViewport(tester);
      final vm = SettingsViewModel(
        repository: _FakeSettingsRepository(
          initialPreferences: const AppPreferences(themeMode: ThemeMode.dark),
        ),
      );

      await tester.pumpWidget(_buildHarness(vm: vm));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(ListTile, 'テーマ'),
        findsOneWidget,
      );
      expect(find.text('ダーク'), findsOneWidget);
    });

    testWidgets('テーマ項目をタップするとダイアログが開き選択でVMが更新される', (
      tester,
    ) async {
      _useTallViewport(tester);
      final vm = SettingsViewModel(
        repository: _FakeSettingsRepository(),
      );

      await tester.pumpWidget(_buildHarness(vm: vm));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, 'テーマ'));
      await tester.pumpAndSettle();

      // ダイアログ内の3択が表示されている
      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SimpleDialog),
          matching: find.text('システム設定に従う'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SimpleDialog),
          matching: find.text('ライト'),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(SimpleDialog),
          matching: find.text('ライト'),
        ),
      );
      await tester.pumpAndSettle();

      expect(vm.preferences.themeMode, ThemeMode.light);
    });

    testWidgets('言語項目の現在値がサブタイトルに表示される', (tester) async {
      _useTallViewport(tester);
      final vm = SettingsViewModel(
        repository: _FakeSettingsRepository(
          initialPreferences: const AppPreferences(language: AppLanguage.en),
        ),
      );

      await tester.pumpWidget(_buildHarness(vm: vm));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(ListTile, '表示言語'),
        findsOneWidget,
      );
      expect(find.text('英語'), findsOneWidget);
    });

    testWidgets('言語項目をタップするとダイアログが開き選択でVMが更新される', (
      tester,
    ) async {
      _useTallViewport(tester);
      final vm = SettingsViewModel(
        repository: _FakeSettingsRepository(),
      );

      await tester.pumpWidget(_buildHarness(vm: vm));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, '表示言語'));
      await tester.pumpAndSettle();

      expect(find.byType(SimpleDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(SimpleDialog),
          matching: find.text('日本語'),
        ),
      );
      await tester.pumpAndSettle();

      expect(vm.preferences.language, AppLanguage.ja);
    });

    testWidgets('バージョン情報がpackage_info_plusから取得して表示される', (tester) async {
      _useTallViewport(tester);
      final vm = SettingsViewModel(
        repository: _FakeSettingsRepository(),
      );

      await tester.pumpWidget(_buildHarness(vm: vm));
      await tester.pumpAndSettle();

      expect(find.text('バージョン'), findsOneWidget);
      expect(find.text('1.2.3'), findsOneWidget);
    });

    testWidgets('ライセンスをタップするとshowLicensePageが開く', (tester) async {
      _useTallViewport(tester);
      final vm = SettingsViewModel(
        repository: _FakeSettingsRepository(),
      );

      await tester.pumpWidget(_buildHarness(vm: vm));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ライセンス'));
      await tester.pumpAndSettle();

      // showLicensePage が開くと LicensePage が現れる
      expect(find.byType(LicensePage), findsOneWidget);
    });
  });
}
