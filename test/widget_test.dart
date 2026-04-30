import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildApp() => MyApp(
    sharedPreferences: prefs,
    locale: const Locale('ja'),
  );

  testWidgets('アプリ起動時にファイル一覧画面が表示される', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('ファイル'), findsWidgets);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('AppBarの設定アイコンをタップすると設定画面に遷移する', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('設定'), findsOneWidget);
  });
}
