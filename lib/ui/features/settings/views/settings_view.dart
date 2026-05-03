import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pocket_sync/domain/models/app_preferences.dart';
import 'package:pocket_sync/l10n/app_localizations.dart';
import 'package:pocket_sync/l10n/l10n_extension.dart';
import 'package:pocket_sync/ui/features/settings/view_models/settings_view_model.dart';
import 'package:pocket_sync/ui/features/settings/views/aws_credentials_form.dart';
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
          _SectionHeader(l10n.settingsAwsSection),
          const AwsCredentialsForm(),
          const Divider(),
          _SectionHeader(l10n.settingsAppearanceSection),
          ListTile(
            title: Text(l10n.settingsTheme),
            subtitle: Text(_themeModeLabel(l10n, vm.preferences.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context, vm),
          ),
          const Divider(),
          _SectionHeader(l10n.settingsLanguageSection),
          ListTile(
            title: Text(l10n.settingsLanguage),
            subtitle: Text(_languageLabel(l10n, vm.preferences.language)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context, vm),
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

  Future<void> _showThemeDialog(
    BuildContext context,
    SettingsViewModel vm,
  ) async {
    final l10n = context.l10n;
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: Text(l10n.settingsTheme),
          children: [
            RadioGroup<ThemeMode>(
              groupValue: vm.preferences.themeMode,
              onChanged: (value) => Navigator.of(dialogContext).pop(value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final mode in ThemeMode.values)
                    RadioListTile<ThemeMode>(
                      title: Text(_themeModeLabel(l10n, mode)),
                      value: mode,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
    if (selected != null && selected != vm.preferences.themeMode) {
      await vm.setThemeMode(selected);
    }
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    SettingsViewModel vm,
  ) async {
    final l10n = context.l10n;
    final selected = await showDialog<AppLanguage>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: Text(l10n.settingsLanguage),
          children: [
            RadioGroup<AppLanguage>(
              groupValue: vm.preferences.language,
              onChanged: (value) => Navigator.of(dialogContext).pop(value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final language in AppLanguage.values)
                    RadioListTile<AppLanguage>(
                      title: Text(_languageLabel(l10n, language)),
                      value: language,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
    if (selected != null && selected != vm.preferences.language) {
      await vm.setLanguage(selected);
    }
  }
}

String _themeModeLabel(AppLocalizations l10n, ThemeMode mode) {
  switch (mode) {
    case ThemeMode.system:
      return l10n.settingsThemeSystem;
    case ThemeMode.light:
      return l10n.settingsThemeLight;
    case ThemeMode.dark:
      return l10n.settingsThemeDark;
  }
}

String _languageLabel(AppLocalizations l10n, AppLanguage language) {
  switch (language) {
    case AppLanguage.system:
      return l10n.settingsLanguageSystem;
    case AppLanguage.ja:
      return l10n.settingsLanguageJapanese;
    case AppLanguage.en:
      return l10n.settingsLanguageEnglish;
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
