import 'package:flutter/material.dart' hide Text;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pandit_app/core/l10n/app_l10n.dart';
import 'package:pandit_app/core/l10n/translations.dart';
import 'package:pandit_app/core/translation/translated_scope.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Verifies the render-layer translation walker — the mobile counterpart of
/// the web app's Google Translate element: it rewrites rendered English text
/// into the selected language (dictionary first) while leaving numeric/amount
/// strings untouched.
void main() {
  testWidgets('renders every text in the selected language', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final en = kAppTranslations['common.search']!['en']!;

    Widget app(Locale locale) => MaterialApp(
          locale: locale,
          debugShowCheckedModeBanner: false,
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.delegates,
          builder: (context, child) =>
              TranslatedScope(child: child ?? const SizedBox.shrink()),
          home: Scaffold(
            body: Column(
              children: [Text(en), const Text('₹1,250')],
            ),
          ),
        );

    // English locale: the walker is inert and text is byte-identical.
    await tester.pumpWidget(app(const Locale('en')));
    await tester.pump();
    expect(
      tester.renderObject<RenderParagraph>(find.text(en)).text.toPlainText(),
      en,
    );

    // Telugu locale: the dictionary copy replaces the English span on the
    // first post-frame walk, while the ₹ amount stays exactly as rendered.
    await tester.pumpWidget(app(const Locale('te')));
    await tester.pump();

    final paragraph = tester.renderObject<RenderParagraph>(find.text(en));
    final translated = paragraph.text.toPlainText();
    expect(translated, isNot(en));
    expect(RegExp(r'[\u0C00-\u0C7F]').hasMatch(translated), isTrue);

    // The walk runs after the frame's layout phase, so it must flush the
    // layout it dirtied — otherwise hit-testing later in the same frame
    // throws "Text layout not available" and taps/drags stop working.
    expect(paragraph.debugNeedsLayout, isFalse);

    expect(
      tester.renderObject<RenderParagraph>(find.text('₹1,250')).text.toPlainText(),
      '₹1,250',
    );
  });
}
