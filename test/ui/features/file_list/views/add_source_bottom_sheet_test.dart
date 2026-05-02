import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/data/repositories/file_list_repository.dart';
import 'package:pocket_sync/data/sources/file_picker_port.dart';
import 'package:pocket_sync/data/sources/image_picker_port.dart';
import 'package:pocket_sync/data/sources/picked_file.dart';
import 'package:pocket_sync/l10n/app_localizations.dart';
import 'package:pocket_sync/ui/features/file_list/view_models/add_source_view_model.dart';
import 'package:pocket_sync/ui/features/file_list/view_models/file_list_view_model.dart';
import 'package:pocket_sync/ui/features/file_list/views/add_source_bottom_sheet.dart';
import 'package:provider/provider.dart';

class _FakeFilePicker implements FilePickerPort {
  int callCount = 0;

  @override
  Future<List<PickedFile>> pickFiles() async {
    callCount += 1;
    return const [];
  }
}

class _FakeImagePicker implements ImagePickerPort {
  int callCount = 0;

  @override
  Future<List<PickedFile>> pickMedia() async {
    callCount += 1;
    return const [];
  }
}

Widget _harness(AddSourceViewModel vm) {
  return MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ChangeNotifierProvider<AddSourceViewModel>.value(
      value: vm,
      child: Builder(
        builder: (context) => Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () => AddSourceBottomSheet.show(context),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late _FakeFilePicker filePicker;
  late _FakeImagePicker imagePicker;
  late AddSourceViewModel vm;

  setUp(() {
    filePicker = _FakeFilePicker();
    imagePicker = _FakeImagePicker();
    vm = AddSourceViewModel(
      filePicker: filePicker,
      imagePicker: imagePicker,
      fileListViewModel: FileListViewModel(
        repository: FileListRepository(),
      ),
    );
  });

  group('AddSourceBottomSheet', () {
    testWidgets('2 つの選択肢が表示される', (tester) async {
      await tester.pumpWidget(_harness(vm));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('ファイルから選択'), findsOneWidget);
      expect(find.text('写真から選択'), findsOneWidget);
    });

    testWidgets('ファイルから選択をタップすると filePicker が呼ばれる', (tester) async {
      await tester.pumpWidget(_harness(vm));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ファイルから選択'));
      await tester.pumpAndSettle();

      expect(filePicker.callCount, 1);
      expect(imagePicker.callCount, 0);
    });

    testWidgets('写真から選択をタップすると imagePicker が呼ばれる', (tester) async {
      await tester.pumpWidget(_harness(vm));
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('写真から選択'));
      await tester.pumpAndSettle();

      expect(imagePicker.callCount, 1);
      expect(filePicker.callCount, 0);
    });
  });
}
