import 'package:flutter/material.dart';

class FileDetailView extends StatelessWidget {
  const FileDetailView({required this.fileId, super.key});

  final String fileId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ファイル詳細')),
      body: Center(child: Text('FileDetail: $fileId（実装予定）')),
    );
  }
}
