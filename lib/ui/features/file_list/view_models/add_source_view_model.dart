import 'package:flutter/foundation.dart';
import 'package:pocket_sync/data/sources/file_picker_port.dart';
import 'package:pocket_sync/data/sources/image_picker_port.dart';
import 'package:pocket_sync/data/sources/picked_file.dart';
import 'package:pocket_sync/ui/features/file_list/view_models/file_list_view_model.dart';

/// ファイル選択導線で発生しうる UI 表示用のエラー区分。
enum AddSourceError {
  /// ピッカーの起動・選択処理で例外が発生した。
  pickerFailed,
}

/// FAB → 2 択ボトムシート → 公式ピッカー の導線を駆動する
/// ViewModel。選択結果を [FileListViewModel] に取り込む。
///
/// `isPicking` は連打防止と進行中インジケータ用に保持する。
/// `lastError` は View 側で SnackBar 等を表示する用途で参照し、
/// 表示後は [clearError] で消すこと。
class AddSourceViewModel extends ChangeNotifier {
  AddSourceViewModel({
    required FilePickerPort filePicker,
    required ImagePickerPort imagePicker,
    required FileListViewModel fileListViewModel,
  }) : _filePicker = filePicker,
       _imagePicker = imagePicker,
       _fileListViewModel = fileListViewModel;

  final FilePickerPort _filePicker;
  final ImagePickerPort _imagePicker;
  final FileListViewModel _fileListViewModel;

  bool _isPicking = false;
  AddSourceError? _lastError;

  bool get isPicking => _isPicking;
  AddSourceError? get lastError => _lastError;

  /// ファイルピッカーを起動する。
  Future<void> pickFromFiles() => _runPicker(_filePicker.pickFiles);

  /// 写真/動画ピッカーを起動する。
  Future<void> pickFromPhotos() => _runPicker(_imagePicker.pickMedia);

  /// View 側でエラー表示後にクリアする。
  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  Future<void> _runPicker(
    Future<List<PickedFile>> Function() picker,
  ) async {
    if (_isPicking) return;
    _isPicking = true;
    _lastError = null;
    notifyListeners();
    try {
      final picked = await picker();
      if (picked.isNotEmpty) {
        _fileListViewModel.addPicked(picked);
      }
    } on Exception {
      _lastError = AddSourceError.pickerFailed;
    } finally {
      _isPicking = false;
      notifyListeners();
    }
  }
}
