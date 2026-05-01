import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

/// アプリ言語の選択肢。`system` を選ぶと端末ロケールに追従する。
enum AppLanguage { system, ja, en }

@immutable
class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.system,
  });

  final ThemeMode themeMode;
  final AppLanguage language;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    AppLanguage? language,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppPreferences &&
        other.themeMode == themeMode &&
        other.language == language;
  }

  @override
  int get hashCode => Object.hash(themeMode, language);
}
