import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/domain/models/sync_status.dart';

void main() {
  group('LocalOnly', () {
    test('全インスタンスは == で等しい', () {
      const a = LocalOnly();
      const b = LocalOnly();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString は LocalOnly()', () {
      const status = LocalOnly();
      expect(status.toString(), 'LocalOnly()');
    });
  });

  group('SyncStatus switch 網羅', () {
    test('LocalOnly を default なしで分岐できる', () {
      const SyncStatus status = LocalOnly();

      final label = switch (status) {
        LocalOnly() => 'local',
      };

      expect(label, 'local');
    });
  });
}
