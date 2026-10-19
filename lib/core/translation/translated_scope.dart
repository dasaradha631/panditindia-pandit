import 'package:flutter/material.dart' hide Text;
import 'package:flutter/rendering.dart';

import 'translation_service.dart';

/// Applies the selected language to **every** string the app renders — the
/// mobile equivalent of the web application's Google Translate element, which
/// rewrites each text node of the DOM (including dynamic API copy such as
/// ceremony names and addresses).
///
/// After every frame the scope walks the render tree and swaps English text
/// nodes for:
///
/// 1. the human-reviewed dictionary copy from `kAppTranslations` whenever its
///    English source matches, otherwise
/// 2. a cached machine translation from [TranslationService] (the same Google
///    Translate engine the web UI uses), fetched once per string per language.
///
/// Text that is already in the chosen script (for example strings produced by
/// `context.tr(...)`) is left untouched, as is all user-entered input — that
/// lives in `RenderEditable`, which this walker deliberately ignores.
///
/// With the English locale the walk exits immediately, so the English app has
/// zero overhead and byte-identical rendering.
class TranslatedScope extends StatefulWidget {
  const TranslatedScope({super.key, required this.child});

  final Widget child;

  @override
  State<TranslatedScope> createState() => _TranslatedScopeState();
}

class _TranslatedScopeState extends State<TranslatedScope> {
  final TranslationService _service = TranslationService.instance;

  String _lang = 'en';
  bool _pendingWalk = false;

  /// Owners of every paragraph mutated during the current walk; flushed
  /// right after the walk (see [_flushMutatedLayout]).
  final Set<PipelineOwner> _dirtyOwners = <PipelineOwner>{};

  static final RegExp _latinLetters = RegExp(r'[A-Za-z]');
  static final RegExp _alreadyLocalized = RegExp(
      '[\u0900-\u097F' // Devanagari (Hindi)
      '\u0B80-\u0BFF' // Tamil
      '\u0C00-\u0C7F' // Telugu
      '\u0C80-\u0CFF' // Kannada
      '\u0600-\u06FF' // Arabic
      '\u4E00-\u9FFF' // CJK
      ']');

  @override
  void initState() {
    super.initState();
    _service.loadFromDisk();
    _service.addListener(_onTranslationsArrived);
    _scheduleWalk();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Depending on Localizations re-walks whenever the language changes.
    _lang = Localizations.localeOf(context).languageCode;
    _scheduleWalk();
  }

  @override
  void dispose() {
    _service.removeListener(_onTranslationsArrived);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _onTranslationsArrived() => _scheduleWalk(forceFrame: true);

  /// Arms a post-frame walk. With [forceFrame] a frame is also requested so
  /// freshly fetched translations are applied even when the UI is idle.
  void _scheduleWalk({bool forceFrame = false}) {
    if (forceFrame) {
      WidgetsBinding.instance.scheduleFrame();
      if (_pendingWalk) return;
    } else if (_pendingWalk) {
      return;
    }
    _pendingWalk = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingWalk = false;
      if (!mounted) return;
      _walk();
      // Keep covering frames the app produces on its own (scrolls, rebuilds,
      // navigation). No frame is requested here — the callback simply waits
      // for the next one, so an idle screen never spins.
      _scheduleWalk();
    });
  }

  // ── render-tree walk ───────────────────────────────────────────────────

  void _walk() {
    if (_lang.isEmpty || _lang == 'en') return;
    final RenderObject? root;
    try {
      root = context.findRenderObject();
    } catch (_) {
      return;
    }
    if (root == null) return;
    _dirtyOwners.clear();
    try {
      _visit(root);
    } catch (_) {
      // Layout in flux (route transition) — retried on the next frame.
    }
    _flushMutatedLayout();
  }

  /// `RenderParagraph.text` invalidates the `TextPainter` layout, but the
  /// frame's layout phase has already run when we walk. Without flushing the
  /// dirty nodes right here, every hit-test issued later in the same frame —
  /// Flutter's mouse tracker and pointer events run as post-frame callbacks —
  /// trips "Text layout not available", which disables tapping and dragging
  /// app-wide. Laying out synchronously also lets the next frame repaint the
  /// translated glyphs as usual.
  void _flushMutatedLayout() {
    if (_dirtyOwners.isEmpty) return;
    for (final owner in _dirtyOwners) {
      try {
        owner.flushLayout();
      } catch (_) {
        // A stray layout error must never break the frame.
      }
    }
    _dirtyOwners.clear();
  }

  void _visit(RenderObject object) {
    // Children first, then the paragraph itself, so mutating a span never
    // happens while its own subtree is being traversed. RenderParagraph is a
    // leaf apart from WidgetSpan children, whose own text lives in nested
    // paragraphs reached through visitChildren.
    object.visitChildren(_visit);
    if (object is RenderParagraph) _translateParagraph(object);
  }

  void _translateParagraph(RenderParagraph paragraph) {
    try {
      final span = paragraph.text;
      final replacement = _translateSpan(span);
      if (!identical(replacement, span)) {
        paragraph.text = replacement;
        final owner = paragraph.owner;
        if (owner != null) _dirtyOwners.add(owner);
      }
    } catch (_) {
      // One bad paragraph must not break the walk; retried next frame.
    }
  }

  // ── span transform ─────────────────────────────────────────────────────

  InlineSpan _translateSpan(InlineSpan span) {
    if (span is! TextSpan) return span;

    final children = span.children;
    List<InlineSpan>? newChildren;
    if (children != null) {
      var changed = false;
      final rebuilt = <InlineSpan>[];
      for (final child in children) {
        final next = _translateSpan(child);
        if (!identical(next, child)) changed = true;
        rebuilt.add(next);
      }
      if (changed) newChildren = rebuilt;
    }

    final source = span.text;
    var text = source;
    if (source != null && source.isNotEmpty) {
      final resolved = _resolve(source);
      if (resolved != null && resolved != source) text = resolved;
    }

    if (identical(newChildren, children) && text == source) return span;

    // Rebuild preserving every field of the original span (style, gesture
    // recognizers, semantics, locale, spell-out, mouse cursor …).
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

  String? _resolve(String source) {
    if (!_needsTranslation(source)) return null;
    final cached = _service.lookup(source, _lang);
    if (cached == null) {
      _service.ensure(source, _lang); // fetched async; applied on a later frame
      return null;
    }
    // Only accept output that actually landed in the target script. An
    // English echo (rate-limit message, failed engine reply …) would
    // otherwise be rendered and then re-fetched as a brand-new source on the
    // next walk — a chain that never settles and shows up as endless
    // flickering. Rejected results simply stay in English.
    return _alreadyLocalized.hasMatch(cached) ? cached : null;
  }

  bool _needsTranslation(String text) {
    final trimmed = text.trim();
    if (trimmed.length < 2) return false;
    // Language names/codes in the switcher stay exactly as authored — the
    // "English" option must not become "ఇంగ్లీష్" when Telugu is active.
    if (TranslationService.isPinned(trimmed)) return false;
    // Already in the target script (dictionary output, foreign text) — skip.
    if (_alreadyLocalized.hasMatch(trimmed)) return false;
    // Numbers, ₹ amounts, booking refs, emoji and single letters are left as
    // they are; anything with real English words is translated, exactly like
    // the web page would be.
    return _latinLetters.allMatches(trimmed).length >= 2;
  }
}
