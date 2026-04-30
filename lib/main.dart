import 'package:flutter/material.dart';
import 'package:pocket_sync/data/repositories/settings_repository.dart';
import 'package:pocket_sync/l10n/app_localizations.dart';
import 'package:pocket_sync/l10n/l10n_extension.dart';
import 'package:pocket_sync/routing/app_router.dart';
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
      ],
      child: MaterialApp.router(
        routerConfig: appRouter,
        onGenerateTitle: (context) => context.l10n.appTitle,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
