// 当面 pickFiles() の 1 メソッドのみで `one_member_abstracts` が
// 発火するが、Provider の型ベース解決で別ポートと衝突しないよう
// 名目型として abstract class を採用している。pickSingleFile() 等の
// 第 2 のメソッドを追加した時点でこの ignore は不要になる。
// ignore_for_file: one_member_abstracts

import 'package:pocket_sync/data/sources/picked_file.dart';

/// プラットフォームのファイルピッカー (SAF / UIDocumentPicker) を
/// 抽象化するインターフェース。
///
/// テスト時は実プラグインを呼ばずフェイクに差し替えるために存在する
/// （単体テストで `MissingPluginException` を回避）。
abstract interface class FilePickerPort {
  /// システムのファイルピッカーを開いてユーザーに選択させる。
  ///
  /// キャンセルや 0 件選択時は空リストを返す（`null` は返さない）。
  Future<List<PickedFile>> pickFiles();
}
