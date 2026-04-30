import 'package:flutter/material.dart';
import 'package:pocket_sync/l10n/l10n_extension.dart';

class FileDetailView extends StatelessWidget {
  const FileDetailView({required this.fileId, super.key});

  final String fileId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fileDetailTitle)),
      body: Center(child: Text(l10n.fileDetailPlaceholder(fileId))),
    );
  }
}
