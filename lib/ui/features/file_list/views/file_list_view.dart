import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FileListView extends StatelessWidget {
  const FileListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ファイル'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: const Center(child: Text('ファイル一覧（実装予定）')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // AddSource modal は後で実装する
        },
        icon: const Icon(Icons.add),
        label: const Text('ソースを追加'),
      ),
    );
  }
}
