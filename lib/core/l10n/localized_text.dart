import 'package:flutter/widgets.dart' hide Text;
import 'package:flutter/widgets.dart' as fw;

import '../translation/translation_service.dart';

/// Drop-in replacement for Flutter's `Text` that translates **at build time**.
///
/// The render-tree walker in `TranslatedScope` can only swap text *after* a
/// frame has been painted, so any widget rebuild (language switch, provider
/// notification, first mount of a route …) painted one frame of English first
/// — the visible "page blinking" whenever a non-English language was active.
///
/// This widget closes that window: its [build] resolves the string through
/// the synchronous dictionary/cache lookup in [TranslationService.resolveSync]
/// *before* the frame's layout and paint phases run, so rebuilds render
/// translated glyphs immediately. Strings whose machine translation has not
/// been fetched yet fall back to English for that one frame and are picked up
/// by the walker as soon as the translation arrives — both layers share the
/// exact same resolution rules, so they can never disagree and flip-flop.
///
/// Files using this widget import it as `Text` and `hide Text` on Flutter's
/// material/widgets/cupertino imports (see the import codemod in this repo).
class Text extends fw.Text {
  /// Identical signature to Flutter's `Text` — existing call sites, including
  /// `const Text(...)`, compile unchanged.
  const Text(
    super.data, {
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.semanticsIdentifier,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
  });

  /// Identical signature to Flutter's `Text.rich`.
  ///
  /// Super parameters are deliberately not used here: they associate with the
  /// `String data` parameter of the unnamed super constructor instead of
  /// `Text.rich`, so the explicit `super.rich(...)` invocation is required.
  // ignore: use_super_parameters
  const Text.rich(
    InlineSpan textSpan, {
    Key? key,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign? textAlign,
    TextDirection? textDirection,
    Locale? locale,
    bool? softWrap,
    TextOverflow? overflow,
    TextScaler? textScaler,
    int? maxLines,
    String? semanticsLabel,
    String? semanticsIdentifier,
    TextWidthBasis? textWidthBasis,
    TextHeightBehavior? textHeightBehavior,
    Color? selectionColor,
  }) : super.rich(
          textSpan,
          key: key,
          style: style,
          strutStyle: strutStyle,
          textAlign: textAlign,
          textDirection: textDirection,
          locale: locale,
          softWrap: softWrap,
          overflow: overflow,
          textScaler: textScaler,
          maxLines: maxLines,
          semanticsLabel: semanticsLabel,
          semanticsIdentifier: semanticsIdentifier,
          textWidthBasis: textWidthBasis,
          textHeightBehavior: textHeightBehavior,
          selectionColor: selectionColor,
        );

  @override
  Widget build(BuildContext context) {
    // Depending on Localizations also rebuilds this widget when the user
    // picks another language.
    final lang = Localizations.maybeLocaleOf(context)?.languageCode;
    if (lang == null || lang == 'en') return super.build(context);
    final service = TranslationService.instance;

    final source = data;
    if (source != null) {
      final translated = service.resolveSync(source, lang);
      if (translated == source) return super.build(context);
      // Build the frame through Flutter's own Text so every default (style
      // merging, text scaling, selection …) behaves exactly as before.
      return fw.Text(
        translated,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        semanticsIdentifier: semanticsIdentifier,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      ).build(context);
    }

    final span = textSpan;
    if (span != null) {
      final translated = _translateSpan(span, lang, service);
      if (identical(translated, span)) return super.build(context);
      return fw.Text.rich(
        translated,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        semanticsIdentifier: semanticsIdentifier,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      ).build(context);
    }
    return super.build(context);
  }

  /// Same span transform the render-tree walker applies, but synchronous and
  /// limited to dictionary/cache hits. Preserves every field of the original
  /// span (style, gesture recognizers, semantics, locale, mouse cursor …).
  InlineSpan _translateSpan(
      InlineSpan span, String lang, TranslationService service) {
    if (span is! TextSpan) return span;

    final children = span.children;
    List<InlineSpan>? newChildren;
    if (children != null) {
      var changed = false;
      final rebuilt = <InlineSpan>[];
      for (final child in children) {
        final next = _translateSpan(child, lang, service);
        if (!identical(next, child)) changed = true;
        rebuilt.add(next);
      }
      if (changed) newChildren = rebuilt;
    }

    final source = span.text;
    var text = source;
    if (source != null && source.isNotEmpty) {
      final resolved = service.resolveSync(source, lang);
      if (resolved != source) text = resolved;
    }

    if (identical(newChildren, children) && text == source) return span;

    return TextSpan(
      text: text,
      children: newChildren ?? children,
      style: span.style,
      recognizer: span.recognizer,
      mouseCursor: span.mouseCursor,
      onEnter: span.onEnter,
      onExit: span.onExit,
      semanticsLabel: span.semanticsLabel,
      semanticsIdentifier: span.semanticsIdentifier,
      locale: span.locale,
      spellOut: span.spellOut,
    );
  }
}
