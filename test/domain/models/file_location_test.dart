import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/domain/models/file_location.dart';

void main() {
  group('LocalPath', () {
    test('同一パスは ==', () {
      const a = LocalPath('/tmp/x');
      const b = LocalPath('/tmp/x');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('異なるパスは !=', () {
      const a = LocalPath('/tmp/a');
      const b = LocalPath('/tmp/b');

      expect(a, isNot(equals(b)));
    });
  });

  group('ContentUri', () {
    test('同一 URI は ==', () {
      const a = ContentUri('content://media/external/images/1');
      const b = ContentUri('content://media/external/images/1');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('異なる URI は !=', () {
      const a = ContentUri('content://x');
      const b = ContentUri('content://y');

      expect(a, isNot(equals(b)));
    });
  });

  test('LocalPath と ContentUri は同じ文字列でも !=', () {
    const a = LocalPath('content://x');
    const b = ContentUri('content://x');

    expect(a, isNot(equals(b)));
  });

  group('FileLocation switch 網羅', () {
    test('LocalPath と ContentUri を default なしで分岐できる', () {
      String label(FileLocation l) => switch (l) {
        LocalPath() => 'path',
        ContentUri() => 'uri',
      };

      expect(label(const LocalPath('/tmp/x')), 'path');
      expect(label(const ContentUri('content://y')), 'uri');
    });
  });
}
