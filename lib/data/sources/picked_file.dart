import 'package:flutter/foundation.dart';
import 'package:pocket_sync/domain/models/file_location.dart';

/// プラットフォームのファイル/写真ピッカーから返される 1 件の選択結果。
///
/// Repository に渡されると `id` / `pickedAt` / `status` が補完され
/// `SyncFile` に変換される。`id` のような Repository が責任を持つ
/// フィールドはここには含めない。
@immutable
class PickedFile {
  const PickedFile({
    required this.displayName,
    required this.location,
    this.sizeBytes,
    this.mimeType,
  });

  final String displayName;
  final FileLocation location;
  final int? sizeBytes;
  final String? mimeType;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PickedFile &&
        other.displayName == displayName &&
        other.location == location &&
        other.sizeBytes == sizeBytes &&
        other.mimeType == mimeType;
  }

  @override
  int get hashCode => Object.hash(displayName, location, sizeBytes, mimeType);
}
