import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/data/repositories/file_list_repository.dart';
import 'package:pocket_sync/data/sources/picked_file.dart';
import 'package:pocket_sync/domain/models/file_location.dart';
import 'package:pocket_sync/domain/models/sync_status.dart';

void main() {
  PickedFile picked({
    String name = 'a.txt',
    int? size = 100,
    String? mime = 'text/plain',
  }) {
    return PickedFile(
      displayName: name,
      location: LocalPath('/tmp/$name'),
      sizeBytes: size,
      mimeType: mime,
    );
  }

  group('FileListRepository', () {
    test('初期状態の files は空', () {
      final repo = FileListRepository();

      expect(repo.files, isEmpty);
    });

    test('addPicked で追加された SyncFile が返り、files に反映される', () {
      final fixedNow = DateTime.utc(2026, 5, 2, 12);
      final repo = FileListRepository(now: () => fixedNow);

      final added = repo.addPicked([picked()]);

      expect(added, hasLength(1));
      expect(added.first.displayName, 'a.txt');
      expect(added.first.status, const LocalOnly());
      expect(added.first.pickedAt, fixedNow);
      expect(repo.files, equals(added));
    });

    test('複数追加で順序が保たれる', () {
      final repo = FileListRepository()
        ..addPicked([
          picked(),
          picked(name: 'b.txt'),
          picked(name: 'c.txt'),
        ]);

      expect(
        repo.files.map((f) => f.displayName).toList(),
        ['a.txt', 'b.txt', 'c.txt'],
      );
    });

    test('(displayName, sizeBytes, mimeType) 一致は重複として無視', () {
      final repo = FileListRepository()..addPicked([picked()]);

      final added = repo.addPicked([
        picked(),
        picked(size: 200),
      ]);

      expect(added, hasLength(1));
      expect(added.first.sizeBytes, 200);
      expect(repo.files, hasLength(2));
    });

    test('id はインスタンスごとに異なる', () {
      final repo = FileListRepository();

      final added = repo.addPicked([
        picked(),
        picked(name: 'b.txt'),
      ]);

      expect(added[0].id, isNot(equals(added[1].id)));
    });

    test('files は unmodifiable で外部から書き換えられない', () {
      final repo = FileListRepository()..addPicked([picked()]);

      expect(repo.files.clear, throwsUnsupportedError);
    });
  });
}
