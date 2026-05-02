import 'package:flutter/material.dart';
import 'package:pocket_sync/data/repositories/file_list_repository.dart';
import 'package:pocket_sync/data/repositories/settings_repository.dart';
import 'package:pocket_sync/data/sources/file_picker_port.dart';
import 'package:pocket_sync/data/sources/file_picker_port_impl.dart';
import 'package:pocket_sync/data/sources/image_picker_port.dart';
import 'package:pocket_sync/data/sources/image_picker_port_impl.dart';
import 'package:pocket_sync/domain/models/app_preferences.dart';
import 'package:pocket_sync/l10n/app_localizations.dart';
import 'package:pocket_sync/l10n/l10n_extension.dart';
import 'package:pocket_sync/routing/app_router.dart';
import 'package:pocket_sync/ui/features/file_list/view_models/add_source_view_model.dart';
import 'package:pocket_sync/ui/features/file_list/view_models/file_list_view_model.dart';
import 'package:pocket_sync/ui/features/settings/view_models/settings_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(sharedPreferences: prefs));
}

class MyApp extends StatelessWidget {
  const MyApp({required this.sharedPreferences, this.locale, super.key});

  final SharedPreferences sharedPreferences;

  /// 端末ロケールを上書きして強制する場合に指定する。テスト用途を想定。
  /// 指定された場合は `SettingsViewModel.preferences.language` の選択より優先される。
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SettingsRepository>(
          create: (_) => SettingsRepository(prefs: sharedPreferences),
        ),
        ChangeNotifierProvider<SettingsViewModel>(
          create: (context) => SettingsViewModel(
            repository: context.read<SettingsRepository>(),
          ),
        ),
        Provider<FileListRepository>(
          create: (_) => FileListRepository(),
        ),
        Provider<FilePickerPort>(
          create: (_) => const FilePickerPortImpl(),
        ),
        Provider<ImagePickerPort>(
          create: (_) => const ImagePickerPortImpl(),
        ),
        ChangeNotifierProvider<FileListViewModel>(
          create: (context) => FileListViewModel(
            repository: context.read<FileListRepository>(),
          ),
        ),
        ChangeNotifierProvider<AddSourceViewModel>(
          create: (context) => AddSourceViewModel(
            filePicker: context.read<FilePickerPort>(),
            imagePicker: context.read<ImagePickerPort>(),
            fileListViewModel: context.read<FileListViewModel>(),
          ),
        ),
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, vm, _) {
          return MaterialApp.router(
            routerConfig: appRouter,
            onGenerateTitle: (context) => context.l10n.appTitle,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: vm.preferences.themeMode,
            locale: locale ?? localeOf(vm.preferences.language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}

/// [AppLanguage] を `MaterialApp.locale` に渡せる [Locale] に変換する。
/// `system` の場合は `null` を返し、端末ロケールに追従させる。
@visibleForTesting
Locale? localeOf(AppLanguage language) {
  switch (language) {
    case AppLanguage.system:
      return null;
    case AppLanguage.ja:
      return const Locale('ja');
    case AppLanguage.en:
      return const Locale('en');
  }
}
