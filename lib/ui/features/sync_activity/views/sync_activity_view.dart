import 'package:flutter/material.dart';
import 'package:pocket_sync/l10n/l10n_extension.dart';

class SyncActivityView extends StatelessWidget {
  const SyncActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncActivityTitle)),
      body: Center(child: Text(l10n.syncActivityPlaceholder)),
    );
  }
}
