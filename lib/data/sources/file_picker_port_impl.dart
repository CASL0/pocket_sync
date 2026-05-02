import 'package:file_picker/file_picker.dart';
import 'package:pocket_sync/data/sources/file_picker_port.dart';
import 'package:pocket_sync/data/sources/picked_file.dart';
import 'package:pocket_sync/domain/models/file_location.dart';

/// 本番用 [FilePickerPort] 実装。`file_picker` パッケージ経由で
/// プラットフォームのドキュメントピッカー (SAF / UIDocumentPicker)
/// を起動する。実行時パーミッションは不要。
class FilePickerPortImpl implements FilePickerPort {
  const FilePickerPortImpl();

  @override
  Future<List<PickedFile>> pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
    );
    if (result == null) return const [];
    final picked = <PickedFile>[];
    for (final f in result.files) {
      final pathOrUri = f.path ?? f.identifier;
      if (pathOrUri == null) continue;
      picked.add(
        PickedFile(
          displayName: f.name,
          location: _toLocation(pathOrUri),
          sizeBytes: f.size,
        ),
      );
    }
    return picked;
  }

  FileLocation _toLocation(String pathOrUri) {
    if (pathOrUri.startsWith('content://')) return ContentUri(pathOrUri);
    return LocalPath(pathOrUri);
  }
}
