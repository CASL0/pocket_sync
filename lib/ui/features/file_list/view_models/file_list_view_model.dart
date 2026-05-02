import 'package:flutter/foundation.dart';
import 'package:pocket_sync/data/repositories/file_list_repository.dart';
import 'package:pocket_sync/data/sources/picked_file.dart';
import 'package:pocket_sync/domain/models/sync_file.dart';

/// 統一ファイル一覧画面（ADR-0001）の ViewModel。
///
/// [FileListRepository] への薄いラッパーで、
/// View からは `files` を `Consumer<FileListViewModel>` で
/// 監視する。書き込みはピッカー導線などから [addPicked] 経由で
/// 行い、Repository 側で `LocalOnly` の SyncFile に変換される。
class FileListViewModel extends ChangeNotifier {
  FileListViewModel({required FileListRepository repository})
    : _repository = repository;

  final FileListRepository _repository;

  /// 現在の一覧。Repository が保持する `unmodifiable` リストを返す。
  List<SyncFile> get files => _repository.files;

  /// ピッカーで選択されたファイル群を一覧に取り込む。
  /// 重複が除外された結果として実際に追加された分を返す。
  List<SyncFile> addPicked(Iterable<PickedFile> picked) {
    final added = _repository.addPicked(picked);
    if (added.isNotEmpty) notifyListeners();
    return added;
  }
}
