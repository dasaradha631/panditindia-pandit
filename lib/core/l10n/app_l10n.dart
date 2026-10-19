import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_language.dart';
import 'translations.dart';

/// Lightweight hand-rolled localization layer.
///
/// We avoid `flutter gen-l10n` / ARB codegen here because the app ships
/// human-reviewed canonical religious copy that must be editable without a
/// codegen step (see the project blueprint's "localized content rather than
/// direct machine translation" requirement). The lookup contract is identical
/// though, so swapping in generated `AppLocalizations` later is mechanical.
class AppL10n {
  AppL10n(this.locale);

  final Locale locale;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n) ?? AppL10n(AppLanguage.en.locale);
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  static List<Locale> get supportedLocales =>
      AppLanguage.values.map((l) => l.locale).toList(growable: false);

  /// Global Material/Cupertino delegates for the supported locales, so date
  /// pickers, text selection menus, and semantics also speak the chosen language.
  static List<LocalizationsDelegate<dynamic>> get delegates => [
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  /// The resolved language, defaulting to English for unknown locales.
  AppLanguage get language => AppLanguage.fromCode(locale.languageCode);

  /// Look up [key] for the current language.
  ///
  /// Falls back: requested language -> English -> the key itself (so a missing
  /// translation degrades to a visible key rather than an empty label).
  String t(String key, [Map<String, dynamic>? params]) {
    var value = kAppTranslations[key]?[language.code] ??
        kAppTranslations[key]?['en'] ??
        key;
    if (params != null) {
      params.forEach((k, v) => value = value.replaceAll('{$k}', '$v'));
    }
    return value;
  }

  /// Interpolation helper for strings that already live in Dart (not the map).
  static String fill(String template, Map<String, dynamic> params) {
    var out = template;
    params.forEach((k, v) => out = out.replaceAll('{$k}', '$v'));
    return out;
  }
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  bool isSupported(Locale locale) => AppLanguage.values.any((l) => l.code == locale.languageCode);

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(AppL10n(locale));
  }

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

/// `context.l10n.t('some.key')`
extension AppL10nX on BuildContext {
  AppL10n get l10n => AppL10n.of(this);

  String tr(String key, [Map<String, dynamic>? params]) => AppL10n.of(this).t(key, params);
}