import 'package:flutter/widgets.dart';
import 'package:pocket_sync/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    if (localizations == null) {
      throw FlutterError(
        'AppLocalizations が見つかりません。MaterialApp の '
        'localizationsDelegates に AppLocalizations.delegate を '
        '登録してください。',
      );
    }
    return localizations;
  }
}
