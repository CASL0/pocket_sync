import 'package:flutter/foundation.dart';
import 'package:pocket_sync/domain/models/file_location.dart';
import 'package:pocket_sync/domain/models/sync_status.dart';

/// ピッカーで選ばれた、同期対象となる 1 ファイルの表現。
///
/// 統一ビュー（ADR-0001）の表示単位で、`status` で同期状態を表す。
@immutable
class SyncFile {
  const SyncFile({
    required this.id,
    required this.displayName,
    required this.location,
    required this.pickedAt,
    required this.status,
    this.sizeBytes,
    this.mimeType,
  });

  /// 一覧内で重複なく扱うための識別子。Repository が採番する。
  final String id;

  /// UI に表示するファイル名。
  final String displayName;

  /// ファイル実体の場所。
  final FileLocation location;

  /// バイト数。ピッカーが返さない場合は `null`。
  final int? sizeBytes;

  /// MIME タイプ（例: `image/jpeg`）。判別不能な場合は `null`。
  final String? mimeType;

  /// ユーザーが選んだ時刻。
  final DateTime pickedAt;

  /// 現在の同期状態。
  final SyncStatus status;

  SyncFile copyWith({
    String? id,
    String? displayName,
    FileLocation? location,
    int? sizeBytes,
    String? mimeType,
    DateTime? pickedAt,
    SyncStatus? status,
  }) {
    return SyncFile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      location: location ?? this.location,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      pickedAt: pickedAt ?? this.pickedAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncFile &&
        other.id == id &&
        other.displayName == displayName &&
        other.location == location &&
        other.sizeBytes == sizeBytes &&
        other.mimeType == mimeType &&
        other.pickedAt == pickedAt &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    location,
    sizeBytes,
    mimeType,
    pickedAt,
    status,
  );
}
