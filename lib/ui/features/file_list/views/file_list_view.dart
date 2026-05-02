import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_sync/domain/models/sync_file.dart';
import 'package:pocket_sync/domain/models/sync_status.dart';
import 'package:pocket_sync/l10n/app_localizations.dart';
import 'package:pocket_sync/l10n/l10n_extension.dart';
import 'package:pocket_sync/ui/features/file_list/view_models/add_source_view_model.dart';
import 'package:pocket_sync/ui/features/file_list/view_models/file_list_view_model.dart';
import 'package:pocket_sync/ui/features/file_list/views/add_source_bottom_sheet.dart';
import 'package:provider/provider.dart';

/// 統一ファイル一覧画面（ADR-0001）。
///
/// - `FileListViewModel.files` を `Consumer` で監視して描画する。
/// - FAB タップで [AddSourceBottomSheet] を開く。
/// - `AddSourceViewModel.lastError` を監視し、SnackBar で通知する。
class FileListView extends StatefulWidget {
  const FileListView({super.key});

  @override
  State<FileListView> createState() => _FileListViewState();
}

class _FileListViewState extends State<FileListView> {
  AddSourceViewModel? _addSourceVm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newVm = context.read<AddSourceViewModel>();
    if (!identical(_addSourceVm, newVm)) {
      _addSourceVm?.removeListener(_onAddSourceChange);
      _addSourceVm = newVm;
      _addSourceVm!.addListener(_onAddSourceChange);
    }
  }

  @override
  void dispose() {
    _addSourceVm?.removeListener(_onAddSourceChange);
    super.dispose();
  }

  void _onAddSourceChange() {
    final vm = _addSourceVm;
    if (vm == null) return;
    final error = vm.lastError;
    if (error == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final message = switch (error) {
      AddSourceError.pickerFailed => l10n.addSourcePickerFailed,
    };
    messenger.showSnackBar(SnackBar(content: Text(message)));
    vm.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fileListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.fileListSettingsTooltip,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Consumer<FileListViewModel>(
        builder: (context, vm, _) {
          final files = vm.files;
          if (files.isEmpty) {
            return Center(child: Text(l10n.fileListEmpty));
          }
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) => _FileListItem(file: files[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddSourceBottomSheet.show(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.fileListAddSource),
      ),
    );
  }
}

class _FileListItem extends StatelessWidget {
  const _FileListItem({required this.file});

  final SyncFile file;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      leading: _statusIcon(file.status),
      title: Text(file.displayName),
      subtitle: Text(_statusLabel(l10n, file.status)),
    );
  }

  Widget _statusIcon(SyncStatus status) => switch (status) {
    LocalOnly() => const Icon(Icons.cloud_off_outlined),
  };

  String _statusLabel(AppLocalizations l10n, SyncStatus status) =>
      switch (status) {
        LocalOnly() => l10n.fileStatusLocalOnly,
      };
}
