import 'package:flutter/foundation.dart';

/// ファイル実体の場所を表すシール型。
///
/// プラットフォームによって参照形式が異なる:
/// - Android で SAF 経由のファイルは `content://` URI として渡される
/// - iOS、または Android のローカルパスは通常のファイルパス
///
/// I/O を扱う層では `switch (location)` で網羅的に分岐し、
/// `default:` を書かずに新規サブクラス追加時にコンパイラへ
/// 検出させる（ADR-0002 と同じ方針）。
sealed class FileLocation {
  const FileLocation();
}

/// ローカルファイルシステム上の絶対パス。
@immutable
final class LocalPath extends FileLocation {
  const LocalPath(this.path);

  final String path;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalPath && other.path == path;
  }

  @override
  int get hashCode => Object.hash(LocalPath, path);

  @override
  String toString() => 'LocalPath($path)';
}

/// Android の `content://` URI。
@immutable
final class ContentUri extends FileLocation {
  const ContentUri(this.uri);

  final String uri;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentUri && other.uri == uri;
  }

  @override
  int get hashCode => Object.hash(ContentUri, uri);

  @override
  String toString() => 'ContentUri($uri)';
}
