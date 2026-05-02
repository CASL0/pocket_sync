import 'package:pocket_sync/data/sources/picked_file.dart';
import 'package:pocket_sync/domain/models/sync_file.dart';
import 'package:pocket_sync/domain/models/sync_status.dart';

/// 選択中のファイル一覧をメモリ内で保持する Repository。
///
/// 永続化は意図的にしない。iOS の `image_picker` は一時パスを返すため
/// 再起動後にパスが失効し、復元しても開けない一覧になる懸念がある。
/// 永続化は SAF / iOS Bookmark と組み合わせた別 ADR の範囲とする
/// （ADR-0006 の「再考のトリガー条件」参照）。
class FileListRepository {
  FileListRepository({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final List<SyncFile> _files = [];
  int _idSeq = 0;

  /// 現在保持しているファイル一覧。呼び出し元での変更を防ぐため
  /// `List.unmodifiable` で包んで返す。
  List<SyncFile> get files => List.unmodifiable(_files);

  /// `incoming` の各要素を `SyncFile` に変換して追加する。
  ///
  /// `(displayName, sizeBytes, mimeType)` が一致するエントリは
  /// 重複として無視する（将来コンテンツハッシュで置き換え予定）。
  /// 実際に追加された分だけを返す。
  List<SyncFile> addPicked(Iterable<PickedFile> incoming) {
    final added = <SyncFile>[];
    for (final picked in incoming) {
      if (_isDuplicate(picked)) continue;
      _idSeq += 1;
      final timestamp = _now();
      final file = SyncFile(
        id: 'sf_${timestamp.microsecondsSinceEpoch}_$_idSeq',
        displayName: picked.displayName,
        location: picked.location,
        sizeBytes: picked.sizeBytes,
        mimeType: picked.mimeType,
        pickedAt: timestamp,
        status: const LocalOnly(),
      );
      _files.add(file);
      added.add(file);
    }
    return added;
  }

  bool _isDuplicate(PickedFile picked) {
    return _files.any(
      (f) =>
          f.displayName == picked.displayName &&
          f.sizeBytes == picked.sizeBytes &&
          f.mimeType == picked.mimeType,
    );
  }
}
