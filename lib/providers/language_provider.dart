import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/l10n/app_language.dart';

/// Global language state for the whole app.
///
/// One instance is registered at the root of `main.dart` and read by every
/// screen via `context.watch<LanguageProvider>()`. Changing the language
/// rebuilds `MaterialApp`, so all screens refresh immediately with no restart
/// and no new account.
class LanguageProvider extends ChangeNotifier {
  static const String storageKey = 'pi_app_language';

  SharedPreferences? _prefs;
  AppLanguage _language = AppLanguage.en;

  AppLanguage get language => _language;

  Locale get locale => _language.locale;

  /// Restore the persisted choice during splash so the first frame is correct.
  Future<void> load() async {
    try {
      final sp = _prefs ??= await SharedPreferences.getInstance();
      _language = AppLanguage.fromCode(sp.getString(storageKey));
    } catch (_) {
      _language = AppLanguage.en;
    }
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    try {
      final sp = _prefs ??= await SharedPreferences.getInstance();
      await sp.setString(storageKey, language.code);
    } catch (_) {}
  }
}