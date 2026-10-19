import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter_test/flutter_test.dart';

import 'package:pandit_app/core/l10n/localized_text.dart';

/// Minimal sync delegate so `Localizations` accepts the tree (it asserts a
/// `WidgetsLocalizations` delegate is present) without pulling in the async
/// Material/Cupertino bundles, keeping the very first frame testable.
class _TestWidgetsLocalizations
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _TestWidgetsLocalizations();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture<WidgetsLocalizations>(
          const DefaultWidgetsLocalizations());

  @override
  bool shouldReload(_TestWidgetsLocalizations old) => false;
}

/// Build-time translation regression coverage.
///
/// The render-tree walker can only swap text *after* a frame has painted, so
/// before the drop-in `Text` existed every widget rebuild painted one frame of
/// English first — the visible "page blinking" whenever a non-English language
/// was selected. These tests pump the widget **without** a `TranslatedScope`,
/// so anything asserted here is resolved by `Text.build` itself, in the very
/// first frame.
void main() {
  Widget wrap(Widget child, String languageCode) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Localizations(
        locale: Locale(languageCode),
        delegates: const <LocalizationsDelegate<dynamic>>[
          _TestWidgetsLocalizations(),
        ],
        child: child,
      ),
    );
  }

  testWidgets('dictionary string is translated in the first frame',
      (tester) async {
    await tester.pumpWidget(wrap(const Text('Cancel'), 'te'));

    final rich = tester.widget<RichText>(find.byType(RichText));
    expect(rich.text.toPlainText(), 'రద్దు');
  });

  testWidgets('English locale renders the source string unchanged',
      (tester) async {
    await tester.pumpWidget(wrap(const Text('Cancel'), 'en'));

    final rich = tester.widget<RichText>(find.byType(RichText));
    expect(rich.text.toPlainText(), 'Cancel');
  });

  testWidgets('text already in the target script is left untouched',
      (tester) async {
    await tester.pumpWidget(wrap(const Text('పూజ'), 'te'));

    final rich = tester.widget<RichText>(find.byType(RichText));
    expect(rich.text.toPlainText(), 'పూజ');
  });

  testWidgets('Text.rich translates span children in the first frame',
      (tester) async {
    await tester.pumpWidget(wrap(
      const Text.rich(TextSpan(children: <InlineSpan>[
        TextSpan(text: 'Cancel'),
        TextSpan(text: ' — ₹51'),
      ])),
      'te',
    ));

    final rich = tester.widget<RichText>(find.byType(RichText));
    expect(rich.text.toPlainText(), 'రద్దు — ₹51');
  });

  testWidgets('rebuilding keeps the translated text (no English flash)',
      (tester) async {
    await tester.pumpWidget(wrap(const Text('Cancel'), 'te'));
    expect(
      tester.widget<RichText>(find.byType(RichText)).text.toPlainText(),
      'రద్దు',
    );

    // Force the element to rebuild (the case that used to reset the render
    // paragraph back to English for a frame).
    await tester.pumpWidget(wrap(const Text('Cancel'), 'te'));
    expect(
      tester.widget<RichText>(find.byType(RichText)).text.toPlainText(),
      'రద్దు',
    );
  });
}

