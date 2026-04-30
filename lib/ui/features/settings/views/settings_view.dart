import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pocket_sync/l10n/l10n_extension.dart';
import 'package:pocket_sync/ui/features/settings/view_models/settings_view_model.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _SectionHeader(l10n.settingsSyncSection),
          SwitchListTile(
            title: Text(l10n.settingsWifiOnly),
            value: vm.settings.wifiOnly,
            onChanged: (v) => vm.setWifiOnly(value: v),
          ),
          SwitchListTile(
            title: Text(l10n.settingsChargingOnly),
            value: vm.settings.chargingOnly,
            onChanged: (v) => vm.setChargingOnly(value: v),
          ),
          SwitchListTile(
            title: Text(l10n.settingsBackgroundSync),
            value: vm.settings.backgroundSync,
            onChanged: (v) => vm.setBackgroundSync(value: v),
          ),
          const Divider(),
          _SectionHeader(l10n.settingsAboutSection),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '';
              return ListTile(
                title: Text(l10n.settingsVersion),
                subtitle: Text(version),
              );
            },
          ),
          ListTile(
            title: Text(l10n.settingsLicenses),
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
