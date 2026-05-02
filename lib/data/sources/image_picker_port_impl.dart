import 'package:image_picker/image_picker.dart' hide PickedFile;
import 'package:pocket_sync/data/sources/image_picker_port.dart';
import 'package:pocket_sync/data/sources/picked_file.dart';
import 'package:pocket_sync/domain/models/file_location.dart';

/// 本番用 [ImagePickerPort] 実装。`image_picker` の
/// `pickMultipleMedia` 経由で写真と動画を選ぶ。iOS は PHPicker、
/// Android は Photo Picker を内部で使うため実行時パーミッションは
/// 不要（古い OS では互換実装にフォールバックする）。
class ImagePickerPortImpl implements ImagePickerPort {
  const ImagePickerPortImpl();

  @override
  Future<List<PickedFile>> pickMedia() async {
    final result = await ImagePicker().pickMultipleMedia();
    return Future.wait([
      for (final x in result)
        x.length().then(
          (size) => PickedFile(
            displayName: x.name,
            location: _toLocation(x.path),
            sizeBytes: size,
            mimeType: x.mimeType,
          ),
        ),
    ]);
  }

  FileLocation _toLocation(String pathOrUri) {
    if (pathOrUri.startsWith('content://')) return ContentUri(pathOrUri);
    return LocalPath(pathOrUri);
  }
}
