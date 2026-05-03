import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/data/repositories/aws_credentials_repository.dart';
import 'package:pocket_sync/domain/models/aws_credentials.dart';
import 'package:pocket_sync/l10n/app_localizations.dart';
import 'package:pocket_sync/ui/features/settings/view_models/aws_credentials_view_model.dart';
import 'package:pocket_sync/ui/features/settings/views/aws_credentials_form.dart';
import 'package:provider/provider.dart';

class _FakeRepository implements AwsCredentialsRepository {
  _FakeRepository({AwsCredentials initial = AwsCredentials.empty})
    : _stored = initial;

  AwsCredentials _stored;
  Exception? saveError;
  Exception? clearError;
  int saveCallCount = 0;
  int clearCallCount = 0;
  Completer<void>? _loadGate;

  /// 次回の `load()` を `releaseLoadGate()` まで完了させない。
  /// isLoading 中の挙動を観察する用。
  void holdLoad() => _loadGate = Completer<void>();

  void releaseLoadGate() => _loadGate?.complete();

  @override
  Future<AwsCredentials> load() async {
    if (_loadGate != null) await _loadGate!.future;
    return _stored;
  }

  @override
  Future<void> save(AwsCredentials creds) async {
    saveCallCount += 1;
    if (saveError != null) throw saveError!;
    _stored = creds;
  }

  @override
  Future<void> clear() async {
    clearCallCount += 1;
    if (clearError != null) throw clearError!;
    _stored = AwsCredentials.empty;
  }
}

const _filled = AwsCredentials(
  accessKeyId: 'AKIATEST123456789',
  secretAccessKey: 'shhhsecret',
  region: 'ap-northeast-1',
  bucketName: 'pocket-sync-test',
);

Widget _harness(_FakeRepository repo) {
  return ChangeNotifierProvider<AwsCredentialsViewModel>(
    create: (_) => AwsCredentialsViewModel(repository: repo),
    child: const MaterialApp(
      locale: Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: AwsCredentialsForm()),
    ),
  );
}

void main() {
  group('AwsCredentialsForm', () {
    testWidgets('isLoading 中は CircularProgressIndicator を表示する', (tester) async {
      final repo = _FakeRepository()..holdLoad();

      await tester.pumpWidget(_harness(repo));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 後続のフレームでローディングが解放され、フォームが表示される
      repo.releaseLoadGate();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Access Key ID'), findsOneWidget);
    });

    testWidgets('bootstrap 後に 4 つの入力欄と 2 つのボタンが表示される', (tester) async {
      await tester.pumpWidget(_harness(_FakeRepository()));
      await tester.pumpAndSettle();

      expect(find.text('Access Key ID'), findsOneWidget);
      expect(find.text('Secret Access Key'), findsOneWidget);
      expect(find.text('リージョン'), findsOneWidget);
      expect(find.text('バケット名'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.text('保存'), findsOneWidget);
      expect(find.text('削除'), findsOneWidget);
    });

    testWidgets('Secret 入力欄は obscureText が有効', (tester) async {
      await tester.pumpWidget(_harness(_FakeRepository()));
      await tester.pumpAndSettle();

      final secretField = tester.widget<TextField>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Secret Access Key'),
          matching: find.byType(TextField),
        ),
      );
      expect(secretField.obscureText, isTrue);
      expect(secretField.enableInteractiveSelection, isFalse);
    });

    testWidgets('保存済み値は Access Key / Region / Bucket だけ初期表示される', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(_FakeRepository(initial: _filled)));
      await tester.pumpAndSettle();

      expect(find.text('AKIATEST123456789'), findsOneWidget);
      expect(find.text('ap-northeast-1'), findsOneWidget);
      expect(find.text('pocket-sync-test'), findsOneWidget);
      // Secret は画面に再表示しない
      expect(find.text('shhhsecret'), findsNothing);
      // hint で「保存済み（未編集）」を出す
      expect(find.text('保存済み（未編集）'), findsOneWidget);
    });

    testWidgets('未入力で保存ボタンは disabled', (tester) async {
      await tester.pumpWidget(_harness(_FakeRepository()));
      await tester.pumpAndSettle();

      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '保存'),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('全項目入力すると保存ボタンが活性化する', (tester) async {
      await tester.pumpWidget(_harness(_FakeRepository()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Access Key ID'),
        'AKIATEST123456789',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Secret Access Key'),
        'shhh',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'リージョン'),
        'ap-northeast-1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'バケット名'),
        'pocket-sync-test',
      );
      await tester.pump();

      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '保存'),
      );
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('保存ボタンをタップすると Repository.save が呼ばれ成功 SnackBar が出る', (
      tester,
    ) async {
      final repo = _FakeRepository();
      await tester.pumpWidget(_harness(repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Access Key ID'),
        'AKIATEST123456789',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Secret Access Key'),
        'shhh',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'リージョン'),
        'ap-northeast-1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'バケット名'),
        'pocket-sync-test',
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pumpAndSettle();

      expect(repo.saveCallCount, 1);
      expect(find.text('保存しました'), findsOneWidget);
    });

    testWidgets('削除ボタンタップで確認ダイアログが開く', (tester) async {
      await tester.pumpWidget(_harness(_FakeRepository(initial: _filled)));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, '削除'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('認証情報を削除'), findsOneWidget);
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('削除する'), findsOneWidget);
    });

    testWidgets('ダイアログで削除を確定すると Repository.clear が呼ばれる', (tester) async {
      final repo = _FakeRepository(initial: _filled);
      await tester.pumpWidget(_harness(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, '削除'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '削除する'));
      await tester.pumpAndSettle();

      expect(repo.clearCallCount, 1);
      expect(find.text('削除しました'), findsOneWidget);
    });

    testWidgets('ダイアログでキャンセルすると Repository.clear は呼ばれない', (tester) async {
      final repo = _FakeRepository(initial: _filled);
      await tester.pumpWidget(_harness(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, '削除'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'キャンセル'));
      await tester.pumpAndSettle();

      expect(repo.clearCallCount, 0);
    });

    testWidgets('保存失敗時はエラー SnackBar が出て Repository は呼ばれている', (tester) async {
      final repo = _FakeRepository()..saveError = Exception('boom');
      await tester.pumpWidget(_harness(repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Access Key ID'),
        'AKIATEST123456789',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Secret Access Key'),
        'shhh',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'リージョン'),
        'ap-northeast-1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'バケット名'),
        'pocket-sync-test',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pumpAndSettle();

      expect(repo.saveCallCount, 1);
      expect(find.text('保存に失敗しました'), findsOneWidget);
    });
  });
}
