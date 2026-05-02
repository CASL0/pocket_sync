import 'package:flutter/foundation.dart';

/// ファイルの同期状態を表すシール型。
///
/// すべてのサブクラスをこのファイルに同居させる。`switch (status)` は
/// `default:` を書かずに網羅的に分岐し、新しい状態を追加した時に
/// コンパイルエラーで未対応箇所を炙り出す（ADR-0002 参照）。
///
/// 将来追加予定のサブクラス:
/// - `Synced(syncedAt)` — リモートと一致する状態
/// - `Uploading(progress)` — アップロード中（0.0..1.0）
/// - `Conflict(local, remote)` — ローカルとリモートで内容が異なる
/// - `SyncError(reason, retryable)` — 同期失敗
sealed class SyncStatus {
  const SyncStatus();
}

/// ローカルにのみ存在し、まだリモートに送られていない状態。
@immutable
final class LocalOnly extends SyncStatus {
  const LocalOnly();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LocalOnly;

  @override
  int get hashCode => (LocalOnly).hashCode;

  @override
  String toString() => 'LocalOnly()';
}
