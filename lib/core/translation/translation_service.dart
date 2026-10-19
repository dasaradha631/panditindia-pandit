import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';
import '../l10n/translations.dart';

/// Runtime translation layer that gives the mobile apps the same behaviour as
/// the web application's Google Translate element.
///
/// The web UI machine-translates its *entire* rendered DOM (including
/// API-sourced copy such as ceremony names, addresses and devotee names).
/// Flutter has no DOM, so this service supplies the translations that the
/// render-tree walker in `TranslatedScope` applies, resolving every string in
/// this order:
///
/// 1. **Dictionary** — the human-reviewed copy already shipped in
///    [kAppTranslations] wins over machine translation whenever its English
///    source matches.
/// 2. **Cache** — translations fetched once per string per language are kept
///    in memory and mirrored to SharedPreferences, so screens switch instantly
///    after the first load and work offline.
/// 3. **Google Translate** — the same engine the web UI uses
///    (`translate.googleapis.com`, no API key), fetched with a small
///    concurrency-limited batcher. Failures back off for a minute and the
///    string simply stays in English — never a crash, never a spinner.
class TranslationService {
  TranslationService._();

  static final TranslationService instance = TranslationService._();

  static const String _cachePrefsKey = 'pi_mt_cache_v1';
  static const int _maxCachedStrings = 4000;
  static const int _maxConcurrent = 4;
  static const Duration _failureBackoff = Duration(minutes: 1);

  /// Language-switcher labels that must never be machine-translated: the
  /// "English" option in the language dropdown has to stay "English" in every
  /// locale (and language codes like `EN` too), instead of being rewritten to
  /// the active language the way the rest of the page is.
  static final Set<String> _pinned = {
    for (final l in AppLanguage.values) ...[l.englishName, l.nativeName, l.code.toUpperCase()],
  };

  /// True when [text] is a language name/code the translator must not touch.
  static bool isPinned(String text) => _pinned.contains(text.trim());

  /// source string -> (language code -> translated string)
  final Map<String, Map<String, String>> _memory = {};

  /// '$lang\u0001$source' keys currently queued or in flight.
  final Set<String> _inFlight = <String>{};
  final Map<String, int> _failedAt = <String, int>{};
  final List<_TranslateJob> _queue = <_TranslateJob>[];
  final List<void Function()> _listeners = <void Function()>[];

  Map<String, Map<String, String>>? _dictIndex;
  SharedPreferences? _prefs;
  bool _diskLoaded = false;
  bool _persistScheduled = false;
  Timer? _debounce;
  int _active = 0;
  DateTime? _googleDownUntil;

  // ── change notification ────────────────────────────────────────────────

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  // ── dictionary (human-reviewed copy first) ─────────────────────────────

  /// English source string -> per-language dictionary entry, built lazily
  /// from [kAppTranslations].
  Map<String, Map<String, String>> get dictionaryIndex {
    final cached = _dictIndex;
    if (cached != null) return cached;
    final index = <String, Map<String, String>>{};
    kAppTranslations.forEach((_, byLang) {
      final source = byLang['en'];
      if (source == null || source.isEmpty) return;
      index[source] = Map<String, String>.from(byLang);
    });
    return _dictIndex = index;
  }

  // ── lookups ────────────────────────────────────────────────────────────

  /// Synchronous resolution: dictionary -> memory/disk cache.
  /// Returns `null` when unknown so the caller can keep the English text and
  /// schedule a fetch with [ensure].
  String? lookup(String source, String lang) {
    if (source.isEmpty || lang.isEmpty) return null;
    if (lang == 'en') return source;
    final fromDict = dictionaryIndex[source]?[lang];
    if (fromDict != null && fromDict.isNotEmpty) return fromDict;
    return _memory[source]?[lang];
  }

  /// Queue a machine-translation fetch for [source]. Deduplicated while in
  /// flight and backed off for a minute after a failure.
  void ensure(String source, String lang) {
    if (lang == 'en' || source.isEmpty) return;
    final key = '$lang\u0001$source';
    if (_inFlight.contains(key)) return;
    final failedAt = _failedAt[key];
    final now = DateTime.now().millisecondsSinceEpoch;
    if (failedAt != null && now - failedAt < _failureBackoff.inMilliseconds) {
      return;
    }
    _inFlight.add(key);
    _queue.add(_TranslateJob(source, lang));
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _pump);
  }

  // ── synchronous build-time resolution ──────────────────────────────────

  static final RegExp _targetScript = RegExp(
      '[\u0900-\u097F' // Devanagari (Hindi)
      '\u0B80-\u0BFF' // Tamil
      '\u0C00-\u0C7F' // Telugu
      '\u0C80-\u0CFF' // Kannada
      '\u0600-\u06FF' // Arabic
      '\u4E00-\u9FFF' // CJK
      ']');
  static final RegExp _latinLetters = RegExp(r'[A-Za-z]');

  /// Whether [text] holds English words that should be translated into
  /// [lang]. Numbers, ₹ amounts, booking refs, emoji and text already set in
  /// the target script are left untouched — the same rules the render-tree
  /// walker in `TranslatedScope` applies.
  bool needsTranslation(String text) {
    final trimmed = text.trim();
    if (trimmed.length < 2) return false;
    if (_pinned.contains(trimmed)) return false;
    if (_targetScript.hasMatch(trimmed)) return false;
    return _latinLetters.allMatches(trimmed).length >= 2;
  }

  /// Resolves [source] synchronously for **build-time** translation (used by
  /// the drop-in `Text` widget so a rebuild paints translated glyphs in the
  /// very same frame instead of flashing English for one frame first).
  ///
  /// Returns the dictionary or cached translation whenever it is available
  /// and actually set in the target script; otherwise returns [source]
  /// unchanged and queues the machine-translation fetch — the render-tree
  /// walker applies that result on a later frame.
  String resolveSync(String source, String lang) {
    if (source.isEmpty || lang.isEmpty || lang == 'en') return source;
    if (!needsTranslation(source)) return source;
    final hit = lookup(source, lang);
    if (hit == null) {
      ensure(source, lang);
      return source;
    }
    // Only accept output that landed in the target script; an English echo
    // (rate-limit reply …) stays English and is never re-fetched.
    return _targetScript.hasMatch(hit) ? hit : source;
  }

  void _pump() {
    while (_active < _maxConcurrent && _queue.isNotEmpty) {
      final job = _queue.removeAt(0);
      _active++;
      _fetch(job.source, job.lang).whenComplete(() {
        _active--;
        _pump();
      });
    }
  }

  /// Hosts tried in order — the same `client=gtx` engine the web Google
  /// Translate widget uses. A browser-like User-Agent is required; Google's
  /// edge refuses the default `Dart/x` agent outright.
  static const List<String> _googleEndpoints = [
    'https://translate.googleapis.com/translate_a/single',
    'https://translate.google.com/translate_a/single',
  ];

  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
  };

  Future<void> _fetch(String source, String lang) async {
    final key = '$lang\u0001$source';
    try {
      final translated = await _translate(source, lang);
      _inFlight.remove(key);
      _failedAt.remove(key);
      _store(source, lang, translated);
      _notify();
    } catch (_) {
      // Offline / throttled / blocked — keep the English text and retry later.
      _inFlight.remove(key);
      _failedAt[key] = DateTime.now().millisecondsSinceEpoch;
    }
  }

  /// Translates one string, splitting very long paragraphs at word boundaries
  /// so the request never exceeds URL length limits.
  Future<String> _translate(String source, String lang) async {
    if (Uri.encodeQueryComponent(source).length <= 6000) {
      return _translatePiece(source, lang);
    }
    final pieces = <String>[];
    final buffer = StringBuffer();
    for (final word in source.split(RegExp(r'\s+'))) {
      if (buffer.isNotEmpty && buffer.length + word.length + 1 > 1400) {
        pieces.add(buffer.toString());
        buffer.clear();
      }
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(word);
    }
    if (buffer.isNotEmpty) pieces.add(buffer.toString());
    final out = StringBuffer();
    for (var i = 0; i < pieces.length; i++) {
      if (i > 0) out.write(' ');
      out.write(await _translatePiece(pieces[i], lang));
    }
    return out.toString();
  }

  /// Tries each engine in order and returns the first success.
  Future<String> _translatePiece(String piece, String lang) async {
    Object? lastFailure;
    final googleUp =
        _googleDownUntil == null || DateTime.now().isAfter(_googleDownUntil!);
    if (googleUp) {
      for (final endpoint in _googleEndpoints) {
        try {
          final uri = Uri.parse('$endpoint?client=gtx&sl=en'
              '&tl=${Uri.encodeQueryComponent(lang)}&dt=t'
              '&q=${Uri.encodeQueryComponent(piece)}');
          final res = await http
              .get(uri, headers: _headers)
              .timeout(const Duration(seconds: 10));
          if (res.statusCode != 200) {
            lastFailure = 'HTTP ${res.statusCode}';
            continue;
          }
          final parsed = _parseGoogleResponse(res.bodyBytes);
          if (parsed == null || parsed.isEmpty) {
            lastFailure = 'unparsable response';
            continue;
          }
          return parsed;
        } catch (e) {
          lastFailure = e;
        }
      }
      // Every Google host failed (blocked or rate-limited) — cool down so
      // subsequent strings skip straight to the fallback instead of
      // hammering Google and deepening the throttle.
      _googleDownUntil = DateTime.now().add(const Duration(minutes: 10));
    }
    // Last resort for short strings: MyMemory, a keyless Google-aggregating
    // API with a small anonymous quota (only used when Google is unreachable).
    if (piece.length <= 450) {
      try {
        final uri = Uri.parse('https://api.mymemory.translated.net/get'
            '?q=${Uri.encodeQueryComponent(piece)}&langpair=en|${Uri.encodeQueryComponent(lang)}');
        final res =
            await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final body = jsonDecode(utf8.decode(res.bodyBytes));
          if (body is Map && body['responseStatus'] == 200) {
            final data = body['responseData'];
            final text = data is Map ? data['translatedText'] as String? : null;
            if (text != null && text.isNotEmpty && !text.contains('MYMEMORY WARNING')) {
              return _unescapeHtml(text);
            }
          }
        }
        lastFailure = 'mymemory unavailable';
      } catch (e) {
        lastFailure = e;
      }
    }
    throw Exception('translate failed: $lastFailure');
  }

  String? _parseGoogleResponse(List<int> bytes) {
    try {
      final body = jsonDecode(utf8.decode(bytes));
      final segments = (body is List && body.isNotEmpty && body[0] is List)
          ? body[0] as List
          : const [];
      final buffer = StringBuffer();
      for (final segment in segments) {
        if (segment is List && segment.isNotEmpty && segment[0] is String) {
          buffer.write(segment[0] as String);
        }
      }
      return buffer.toString();
    } catch (_) {
      return null;
    }
  }

  String _unescapeHtml(String value) => value
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');

  // ── persistence ────────────────────────────────────────────────────────

  /// Loads the on-disk cache. Safe to call repeatedly.
  Future<void> loadFromDisk() async {
    if (_diskLoaded) return;
    _diskLoaded = true;
    try {
      final sp = _prefs ??= await SharedPreferences.getInstance();
      final raw = sp.getString(_cachePrefsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      decoded.forEach((source, byLang) {
        if (byLang is Map<String, dynamic>) {
          final inner = <String, String>{};
          byLang.forEach((lang, value) {
            if (value is String) inner[lang] = value;
          });
          if (inner.isNotEmpty) _memory[source] = inner;
        }
      });
    } catch (_) {
      // Corrupt cache — it rebuilds itself as strings are translated.
    }
  }

  void _store(String source, String lang, String translated) {
    _memory.putIfAbsent(source, () => <String, String>{})[lang] = translated;
    _schedulePersist();
  }

  void _schedulePersist() {
    if (_persistScheduled) return;
    _persistScheduled = true;
    Timer(const Duration(seconds: 2), () async {
      _persistScheduled = false;
      try {
        final sp = _prefs ??= await SharedPreferences.getInstance();
        while (_memory.length > _maxCachedStrings) {
          _memory.remove(_memory.keys.first);
        }
        await sp.setString(_cachePrefsKey, jsonEncode(_memory));
      } catch (_) {
        // Disk full / prefs unavailable — memory cache still works.
      }
    });
  }
}

class _TranslateJob {
  const _TranslateJob(this.source, this.lang);

  final String source;
  final String lang;
}
