import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocket_sync/l10n/l10n_extension.dart';

class FileListView extends StatelessWidget {
  const FileListView({super.key});

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
      body: Center(child: Text(l10n.fileListPlaceholder)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // AddSource modal は後で実装する
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.fileListAddSource),
      ),
    );
  }
}
