import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/domain/models/file_location.dart';
import 'package:pocket_sync/domain/models/sync_file.dart';
import 'package:pocket_sync/domain/models/sync_status.dart';

void main() {
  final pickedAt = DateTime.utc(2026, 5, 2, 12);

  SyncFile sample({
    String id = 'sf_1',
    String displayName = 'a.txt',
  }) {
    return SyncFile(
      id: id,
      displayName: displayName,
      location: const LocalPath('/tmp/a.txt'),
      sizeBytes: 100,
      mimeType: 'text/plain',
      pickedAt: pickedAt,
      status: const LocalOnly(),
    );
  }

  group('SyncFile', () {
    test('全フィールド一致なら ==', () {
      final a = sample();
      final b = sample();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('id が違えば !=', () {
      final a = sample();
      final b = sample(id: 'sf_2');

      expect(a, isNot(equals(b)));
    });

    test('copyWith は指定フィールドだけ更新する', () {
      final a = sample();

      final b = a.copyWith(displayName: 'b.txt');

      expect(b.displayName, 'b.txt');
      expect(b.id, a.id);
      expect(b.location, a.location);
      expect(b.sizeBytes, a.sizeBytes);
      expect(b.mimeType, a.mimeType);
      expect(b.pickedAt, a.pickedAt);
      expect(b.status, a.status);
    });

    test('sizeBytes / mimeType は省略可で null になる', () {
      final a = SyncFile(
        id: 'sf_1',
        displayName: 'a.bin',
        location: const LocalPath('/tmp/a.bin'),
        pickedAt: pickedAt,
        status: const LocalOnly(),
      );

      expect(a.sizeBytes, isNull);
      expect(a.mimeType, isNull);
    });
  });
}
