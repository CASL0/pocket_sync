import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/data/repositories/file_list_repository.dart';
import 'package:pocket_sync/data/sources/picked_file.dart';
import 'package:pocket_sync/domain/models/file_location.dart';
import 'package:pocket_sync/ui/features/file_list/view_models/file_list_view_model.dart';

void main() {
  PickedFile picked({String name = 'a.txt'}) {
    return PickedFile(
      displayName: name,
      location: LocalPath('/tmp/$name'),
      sizeBytes: 100,
      mimeType: 'text/plain',
    );
  }

  group('FileListViewModel', () {
    test('Repository の files をそのまま公開する', () {
      final repo = FileListRepository()..addPicked([picked()]);
      final vm = FileListViewModel(repository: repo);

      expect(vm.files, hasLength(1));
      expect(vm.files.first.displayName, 'a.txt');
    });

    test('addPicked で notifyListeners が呼ばれ、files に反映される', () {
      final vm = FileListViewModel(repository: FileListRepository());
      var notified = 0;
      vm.addListener(() => notified += 1);

      final added = vm.addPicked([picked()]);

      expect(notified, 1);
      expect(added, hasLength(1));
      expect(vm.files, hasLength(1));
    });

    test('重複のみで実追加 0 件なら notifyListeners を呼ばない', () {
      final repo = FileListRepository()..addPicked([picked()]);
      final vm = FileListViewModel(repository: repo);
      var notified = 0;
      vm.addListener(() => notified += 1);

      final added = vm.addPicked([picked()]);

      expect(notified, 0);
      expect(added, isEmpty);
      expect(vm.files, hasLength(1));
    });
  });
}
