import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/data/repositories/file_list_repository.dart';
import 'package:pocket_sync/data/sources/file_picker_port.dart';
import 'package:pocket_sync/data/sources/image_picker_port.dart';
import 'package:pocket_sync/data/sources/picked_file.dart';
import 'package:pocket_sync/domain/models/file_location.dart';
import 'package:pocket_sync/l10n/app_localizations.dart';
import 'package:pocket_sync/ui/features/file_list/view_models/add_source_view_model.dart';
import 'package:pocket_sync/ui/features/file_list/view_models/file_list_view_model.dart';
import 'package:pocket_sync/ui/features/file_list/views/file_list_view.dart';
import 'package:provider/provider.dart';

class _FakeFilePicker implements FilePickerPort {
  @override
  Future<List<PickedFile>> pickFiles() async => const [];
}

class _FakeImagePicker implements ImagePickerPort {
  @override
  Future<List<PickedFile>> pickMedia() async => const [];
}

class _ThrowingFilePicker implements FilePickerPort {
  @override
  Future<List<PickedFile>> pickFiles() async => throw Exception('boom');
}

Widget _harness({
  required FileListViewModel listVm,
  required AddSourceViewModel addSourceVm,
}) {
  return MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<FileListViewModel>.value(value: listVm),
        ChangeNotifierProvider<AddSourceViewModel>.value(value: addSourceVm),
      ],
      child: const FileListView(),
    ),
  );
}

({FileListViewModel listVm, AddSourceViewModel addSourceVm}) _buildVms({
  FileListRepository? repository,
  FilePickerPort? filePicker,
  ImagePickerPort? imagePicker,
}) {
  final repo = repository ?? FileListRepository();
  final listVm = FileListViewModel(repository: repo);
  final addSourceVm = AddSourceViewModel(
    filePicker: filePicker ?? _FakeFilePicker(),
    imagePicker: imagePicker ?? _FakeImagePicker(),
    fileListViewModel: listVm,
  );
  return (listVm: listVm, addSourceVm: addSourceVm);
}

void main() {
  group('FileListView', () {
    testWidgets('一覧が空のときに案内文が表示される', (tester) async {
      final vms = _buildVms();

      await tester.pumpWidget(
        _harness(listVm: vms.listVm, addSourceVm: vms.addSourceVm),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('まだファイルがありません。右下の + から追加してください。'),
        findsOneWidget,
      );
    });

    testWidgets('一覧が非空のときに displayName とステータスラベルが表示される', (tester) async {
      final repo = FileListRepository()
        ..addPicked([
          const PickedFile(
            displayName: 'photo.jpg',
            location: LocalPath('/tmp/photo.jpg'),
            sizeBytes: 1024,
            mimeType: 'image/jpeg',
          ),
        ]);
      final vms = _buildVms(repository: repo);

      await tester.pumpWidget(
        _harness(listVm: vms.listVm, addSourceVm: vms.addSourceVm),
      );
      await tester.pumpAndSettle();

      expect(find.text('photo.jpg'), findsOneWidget);
      expect(find.text('ローカルのみ'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });

    testWidgets('FAB タップで 2 択ボトムシートが開く', (tester) async {
      final vms = _buildVms();

      await tester.pumpWidget(
        _harness(listVm: vms.listVm, addSourceVm: vms.addSourceVm),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('ファイルから選択'), findsOneWidget);
      expect(find.text('写真から選択'), findsOneWidget);
    });

    testWidgets('ピッカー失敗時に SnackBar で文言が表示される', (tester) async {
      final vms = _buildVms(filePicker: _ThrowingFilePicker());

      await tester.pumpWidget(
        _harness(listVm: vms.listVm, addSourceVm: vms.addSourceVm),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ファイルから選択'));
      await tester.pumpAndSettle();

      expect(find.text('ピッカーを開けませんでした'), findsOneWidget);
    });
  });
}
