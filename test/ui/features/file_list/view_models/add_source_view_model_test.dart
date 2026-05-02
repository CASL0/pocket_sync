import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/data/repositories/file_list_repository.dart';
import 'package:pocket_sync/data/sources/file_picker_port.dart';
import 'package:pocket_sync/data/sources/image_picker_port.dart';
import 'package:pocket_sync/data/sources/picked_file.dart';
import 'package:pocket_sync/domain/models/file_location.dart';
import 'package:pocket_sync/ui/features/file_list/view_models/add_source_view_model.dart';
import 'package:pocket_sync/ui/features/file_list/view_models/file_list_view_model.dart';

class _FakeFilePicker implements FilePickerPort {
  _FakeFilePicker({this.result = const [], this.error});

  final List<PickedFile> result;
  final Exception? error;
  int callCount = 0;
  Completer<void>? _gate;

  void hold() => _gate = Completer<void>();
  void release() => _gate?.complete();

  @override
  Future<List<PickedFile>> pickFiles() async {
    callCount += 1;
    if (_gate != null) await _gate!.future;
    if (error != null) throw error!;
    return result;
  }
}

class _FakeImagePicker implements ImagePickerPort {
  _FakeImagePicker({this.result = const [], this.error});

  final List<PickedFile> result;
  final Exception? error;
  int callCount = 0;

  @override
  Future<List<PickedFile>> pickMedia() async {
    callCount += 1;
    if (error != null) throw error!;
    return result;
  }
}

PickedFile _picked(String name) {
  return PickedFile(
    displayName: name,
    location: LocalPath('/tmp/$name'),
    sizeBytes: 100,
    mimeType: 'text/plain',
  );
}

void main() {
  late FileListViewModel listVm;
  late _FakeFilePicker filePicker;
  late _FakeImagePicker imagePicker;
  late AddSourceViewModel vm;

  setUp(() {
    listVm = FileListViewModel(repository: FileListRepository());
    filePicker = _FakeFilePicker();
    imagePicker = _FakeImagePicker();
    vm = AddSourceViewModel(
      filePicker: filePicker,
      imagePicker: imagePicker,
      fileListViewModel: listVm,
    );
  });

  group('AddSourceViewModel', () {
    test('初期状態は isPicking=false / lastError=null', () {
      expect(vm.isPicking, isFalse);
      expect(vm.lastError, isNull);
    });

    test('pickFromFiles 正常系: 選択結果が一覧に取り込まれる', () async {
      filePicker = _FakeFilePicker(result: [_picked('a.txt')]);
      vm = AddSourceViewModel(
        filePicker: filePicker,
        imagePicker: imagePicker,
        fileListViewModel: listVm,
      );

      await vm.pickFromFiles();

      expect(filePicker.callCount, 1);
      expect(listVm.files.map((f) => f.displayName), ['a.txt']);
      expect(vm.isPicking, isFalse);
      expect(vm.lastError, isNull);
    });

    test('pickFromFiles キャンセル (空リスト): 一覧変化なし、エラーなし', () async {
      await vm.pickFromFiles();

      expect(filePicker.callCount, 1);
      expect(listVm.files, isEmpty);
      expect(vm.lastError, isNull);
    });

    test('pickFromFiles 例外時: lastError=pickerFailed', () async {
      filePicker = _FakeFilePicker(error: Exception('boom'));
      vm = AddSourceViewModel(
        filePicker: filePicker,
        imagePicker: imagePicker,
        fileListViewModel: listVm,
      );

      await vm.pickFromFiles();

      expect(vm.lastError, AddSourceError.pickerFailed);
      expect(vm.isPicking, isFalse);
      expect(listVm.files, isEmpty);
    });

    test('pickFromPhotos 正常系: 選択結果が一覧に取り込まれる', () async {
      imagePicker = _FakeImagePicker(result: [_picked('img.jpg')]);
      vm = AddSourceViewModel(
        filePicker: filePicker,
        imagePicker: imagePicker,
        fileListViewModel: listVm,
      );

      await vm.pickFromPhotos();

      expect(imagePicker.callCount, 1);
      expect(listVm.files.map((f) => f.displayName), ['img.jpg']);
    });

    test('pickFromPhotos 例外時: lastError=pickerFailed', () async {
      imagePicker = _FakeImagePicker(error: Exception('boom'));
      vm = AddSourceViewModel(
        filePicker: filePicker,
        imagePicker: imagePicker,
        fileListViewModel: listVm,
      );

      await vm.pickFromPhotos();

      expect(vm.lastError, AddSourceError.pickerFailed);
    });

    test('clearError で lastError が null になり notify される', () async {
      filePicker = _FakeFilePicker(error: Exception('boom'));
      vm = AddSourceViewModel(
        filePicker: filePicker,
        imagePicker: imagePicker,
        fileListViewModel: listVm,
      );
      await vm.pickFromFiles();
      var notified = 0;
      vm
        ..addListener(() => notified += 1)
        ..clearError();

      expect(vm.lastError, isNull);
      expect(notified, 1);
    });

    test('clearError は lastError が null なら no-op', () {
      var notified = 0;
      vm
        ..addListener(() => notified += 1)
        ..clearError();

      expect(notified, 0);
    });

    test('isPicking 中の二重呼び出しは無視される', () async {
      filePicker.hold();
      final first = vm.pickFromFiles();
      // 進行中 (gate で待機中) のうちに 2 回目を呼ぶ
      await vm.pickFromFiles();

      expect(filePicker.callCount, 1);
      expect(vm.isPicking, isTrue);

      filePicker.release();
      await first;

      expect(vm.isPicking, isFalse);
      expect(filePicker.callCount, 1);
    });

    test('pickFromFiles 中は isPicking=true、完了時に false', () async {
      filePicker.hold();
      final transitions = <bool>[];
      vm.addListener(() => transitions.add(vm.isPicking));

      final future = vm.pickFromFiles();
      filePicker.release();
      await future;

      expect(transitions.first, isTrue);
      expect(transitions.last, isFalse);
    });
  });
}
