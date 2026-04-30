import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pocket_sync/ui/features/settings/view_models/settings_view_model.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const _SectionHeader('同期'),
          SwitchListTile(
            title: const Text('Wi-Fi接続時のみ同期'),
            value: vm.settings.wifiOnly,
            onChanged: (v) => vm.setWifiOnly(value: v),
          ),
          SwitchListTile(
            title: const Text('充電中のみ同期'),
            value: vm.settings.chargingOnly,
            onChanged: (v) => vm.setChargingOnly(value: v),
          ),
          SwitchListTile(
            title: const Text('バックグラウンド同期'),
            value: vm.settings.backgroundSync,
            onChanged: (v) => vm.setBackgroundSync(value: v),
          ),
          const Divider(),
          const _SectionHeader('アプリについて'),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '';
              return ListTile(
                title: const Text('バージョン'),
                subtitle: Text(version),
              );
            },
          ),
          ListTile(
            title: const Text('ライセンス'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(context: context),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
