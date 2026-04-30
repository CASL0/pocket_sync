import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/domain/models/sync_settings.dart';

void main() {
  group('SyncSettings', () {
    test('デフォルトコンストラクタは全フラグfalse', () {
      const settings = SyncSettings();

      expect(settings.wifiOnly, isFalse);
      expect(settings.chargingOnly, isFalse);
      expect(settings.backgroundSync, isFalse);
    });

    test('明示指定したフラグが反映される', () {
      const settings = SyncSettings(
        wifiOnly: true,
        backgroundSync: true,
      );

      expect(settings.wifiOnly, isTrue);
      expect(settings.chargingOnly, isFalse);
      expect(settings.backgroundSync, isTrue);
    });

    test('copyWithは指定フィールドだけ書き換える', () {
      const original = SyncSettings();

      final updated = original.copyWith(wifiOnly: true);

      expect(updated.wifiOnly, isTrue);
      expect(updated.chargingOnly, isFalse);
      expect(updated.backgroundSync, isFalse);
    });

    test('copyWithでnullを渡すと既存値を維持する', () {
      const original = SyncSettings(
        wifiOnly: true,
        chargingOnly: true,
        backgroundSync: true,
      );

      final updated = original.copyWith();

      expect(updated.wifiOnly, isTrue);
      expect(updated.chargingOnly, isTrue);
      expect(updated.backgroundSync, isTrue);
    });

    test('全フィールド一致するインスタンスは==で等しい', () {
      const a = SyncSettings(wifiOnly: true);
      const b = SyncSettings(wifiOnly: true);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('フィールドが異なるインスタンスは==で等しくない', () {
      const a = SyncSettings(wifiOnly: true);
      const b = SyncSettings();

      expect(a, isNot(equals(b)));
    });
  });
}
