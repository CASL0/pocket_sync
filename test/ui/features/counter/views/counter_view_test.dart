import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/data/repositories/counter_repository.dart';
import 'package:pocket_sync/ui/features/counter/view_models/counter_view_model.dart';
import 'package:pocket_sync/ui/features/counter/views/counter_view.dart';

void main() {
  late CounterRepository repository;
  late CounterViewModel viewModel;

  setUp(() {
    repository = CounterRepository();
    viewModel = CounterViewModel(counterRepository: repository);
  });

  Widget buildSubject() => MaterialApp(
    home: CounterView(viewModel: viewModel),
  );

  testWidgets('初期表示でカウントが 0 である', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('ボタンタップでカウントが 1 増える', (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('ボタンを 3 回タップするとカウントが 3 になる', (tester) async {
    await tester.pumpWidget(buildSubject());

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
    }

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('説明テキストが表示される', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(
      find.text('You have pushed the button this many times:'),
      findsOneWidget,
    );
  });
}
