import 'package:flutter/material.dart';

/// Every language the app ships localized UI content for.
///
/// Phase 1 (per project architecture blueprint): English, Telugu, Hindi,
/// Tamil, Kannada. Phase 2 adds Malayalam, Marathi, Gujarati, Bengali, Odia.
enum AppLanguage {
  en('en', 'English', 'English'),
  te('te', 'Telugu', 'తెలుగు'),
  hi('hi', 'Hindi', 'हिन्दी'),
  ta('ta', 'Tamil', 'தமிழ்'),
  kn('kn', 'Kannada', 'ಕನ್ನಡ');

  const AppLanguage(this.code, this.englishName, this.nativeName);

  final String code;
  final String englishName;
  final String nativeName;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) {
    final c = (code ?? '').trim().toLowerCase();
    for (final l in AppLanguage.values) {
      if (l.code == c) return l;
    }
    // Match on the primary subtag so 'te-IN' / 'te_IN' resolve too.
    final primary = c.split(RegExp('[-_]')).first;
    for (final l in AppLanguage.values) {
      if (l.code == primary) return l;
    }
    return AppLanguage.en;
  }
}