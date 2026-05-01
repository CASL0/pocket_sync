import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_sync/domain/models/app_preferences.dart';

void main() {
  group('AppPreferences', () {
    test('デフォルトコンストラクタはsystem/system', () {
      const prefs = AppPreferences();

      expect(prefs.themeMode, ThemeMode.system);
      expect(prefs.language, AppLanguage.system);
    });

    test('明示指定した値が反映される', () {
      const prefs = AppPreferences(
        themeMode: ThemeMode.dark,
        language: AppLanguage.en,
      );

      expect(prefs.themeMode, ThemeMode.dark);
      expect(prefs.language, AppLanguage.en);
    });

    test('copyWithは指定フィールドだけ書き換える', () {
      const original = AppPreferences();

      final updated = original.copyWith(themeMode: ThemeMode.light);

      expect(updated.themeMode, ThemeMode.light);
      expect(updated.language, AppLanguage.system);
    });

    test('全フィールド一致するインスタンスは==で等しい', () {
      const a = AppPreferences(
        themeMode: ThemeMode.dark,
        language: AppLanguage.ja,
      );
      const b = AppPreferences(
        themeMode: ThemeMode.dark,
        language: AppLanguage.ja,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('フィールドが異なるインスタンスは==で等しくない', () {
      const a = AppPreferences(themeMode: ThemeMode.dark);
      const b = AppPreferences(themeMode: ThemeMode.light);

      expect(a, isNot(equals(b)));
    });
  });
}
