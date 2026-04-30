import 'package:flutter/material.dart';

class SyncActivityView extends StatelessWidget {
  const SyncActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アクティビティ')),
      body: const Center(child: Text('同期アクティビティ（実装予定）')),
    );
  }
}
