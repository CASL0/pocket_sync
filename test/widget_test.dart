import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/main.dart';

void main() {
  testWidgets('アプリ起動時にファイル一覧画面が表示される', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('ファイル'), findsWidgets);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('AppBarの設定アイコンをタップすると設定画面に遷移する', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('設定'), findsOneWidget);
  });
}
