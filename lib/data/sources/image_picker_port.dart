// 当面 pickMedia() の 1 メソッドのみで `one_member_abstracts` が
// 発火するが、Provider の型ベース解決で別ポートと衝突しないよう
// 名目型として abstract class を採用している。pickFromCamera() 等の
// 第 2 のメソッドを追加した時点でこの ignore は不要になる。
// ignore_for_file: one_member_abstracts

import 'package:pocket_sync/data/sources/picked_file.dart';

/// プラットフォームの写真/動画ピッカー (PHPicker / Photo Picker) を
/// 抽象化するインターフェース。
///
/// iOS では PHPicker、Android では Photo Picker（古い端末では
/// 互換実装）を内部で使う想定。いずれもシステムが選択 UI を
/// 提供するため、本ポート経由で呼ぶ限り実行時パーミッションは
/// 不要（ADR-0006 参照）。
abstract interface class ImagePickerPort {
  /// 写真/動画を 1 枚以上選ばせる。
  ///
  /// キャンセルや 0 件選択時は空リストを返す（`null` は返さない）。
  Future<List<PickedFile>> pickMedia();
}
