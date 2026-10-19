import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Shared test environment setup.
///
/// Two things the app gets for free at runtime have to be provided explicitly in
/// widget tests:
///
/// * `intl` date locale data, which the app loads through its localization
///   delegates but which is absent in a bare `MaterialApp`.
/// * Real Roboto faces. The default test font draws every glyph as a full-width
///   box, which inflates text and causes overflow failures that never happen on
///   a real device.
class TestEnvironment {
  TestEnvironment._();

  static String? _fontFamily;

  /// Family name for `ThemeData(fontFamily:)`, or null when the SDK fonts are
  /// unavailable and the default test font has to be used.
  static String? get fontFamily => _fontFamily;

  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;

    await initializeDateFormatting();

    final fonts = _robotoFonts();
    for (final entry in fonts.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(
          Future<ByteData>.value(
            ByteData.sublistView(File(entry.value).readAsBytesSync()),
          ),
        );
      await loader.load();
    }
    _fontFamily = fonts.isEmpty ? null : 'Roboto';
  }
}

/// Roboto faces shipped with the Flutter SDK, keyed by family name.
Map<String, String> _robotoFonts() {
  final root =
      Platform.environment['FLUTTER_ROOT'] ?? _flutterRootFromExecutable();
  if (root == null) return const {};
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (!dir.existsSync()) return const {};
  final wanted = <String, String>{
    'Roboto': 'roboto-regular.ttf',
    'Roboto-Medium': 'roboto-medium.ttf',
    'Roboto-Bold': 'roboto-bold.ttf',
  };
  return {
    for (final family in wanted.keys)
      if (File('${dir.path}\\${wanted[family]}').existsSync())
        family: '${dir.path}\\${wanted[family]}',
  };
}

String? _flutterRootFromExecutable() {
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 5; i++) {
    if (Directory('${dir.path}/bin/cache').existsSync()) return dir.path;
    dir = dir.parent;
  }
  return null;
}
