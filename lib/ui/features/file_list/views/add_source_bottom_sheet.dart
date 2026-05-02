import 'package:flutter/material.dart';
import 'package:pocket_sync/l10n/l10n_extension.dart';
import 'package:pocket_sync/ui/features/file_list/view_models/add_source_view_model.dart';
import 'package:provider/provider.dart';

/// FAB タップで開かれる 2 択ボトムシート（ADR-0006）。
///
/// 「ファイルから選択」「写真から選択」のいずれかをタップすると
/// ボトムシートを閉じてから対応する公式ピッカーを起動する。
/// （ピッカーを先に閉じる方が UX が滑らか）
class AddSourceBottomSheet extends StatelessWidget {
  const AddSourceBottomSheet({required this.viewModel, super.key});

  final AddSourceViewModel viewModel;

  /// ボトムシートを表示するヘルパー。呼び出し元の Provider ツリーから
  /// `AddSourceViewModel` を解決し、子ウィジェットへ手渡す。
  static Future<void> show(BuildContext context) {
    final vm = context.read<AddSourceViewModel>();
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => AddSourceBottomSheet(viewModel: vm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(l10n.addSourceFromFiles),
            onTap: () async {
              Navigator.of(context).pop();
              await viewModel.pickFromFiles();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.addSourceFromPhotos),
            onTap: () async {
              Navigator.of(context).pop();
              await viewModel.pickFromPhotos();
            },
          ),
        ],
      ),
    );
  }
}
