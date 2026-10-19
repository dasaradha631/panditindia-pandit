import 'package:flutter/material.dart' hide Text;
import 'package:provider/provider.dart';

import '../l10n/app_l10n.dart';
import '../l10n/app_language.dart';
import '../../providers/language_provider.dart';
import 'package:pandit_app/core/l10n/localized_text.dart';

/// Compact inline language row used on the Login and Register screens.
///
/// Mirrors the web app's 3-button switcher, expanded to the Phase 1 language
/// set. Selecting immediately applies the language app-wide.
class LanguageSelectorBar extends StatelessWidget {
  const LanguageSelectorBar({super.key, this.onDark = false, this.compact = false});

  /// True when rendered over the gradient hero header of Login.
  final bool onDark;

  /// Tighter padding variant for dense layouts.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final current = context.watch<LanguageProvider>().language;
    final fg = onDark ? Colors.white : null;
    final divider = onDark ? Colors.white24 : Theme.of(context).dividerColor;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: onDark ? Colors.white.withValues(alpha: 0.28) : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.translate_rounded, size: compact ? 15 : 17, color: fg),
          SizedBox(width: compact ? 6 : 10),
          for (var i = 0; i < AppLanguage.values.length; i++) ...[
            if (i > 0) _Sep(color: divider),
            _LangButton(
              language: AppLanguage.values[i],
              selected: AppLanguage.values[i] == current,
              onDark: onDark,
            ),
          ],
        ],
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 12, color: color);
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({required this.language, required this.selected, required this.onDark});

  final AppLanguage language;
  final bool selected;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final base = onDark ? Colors.white : null;
    final color = selected
        ? (onDark ? Colors.white : Theme.of(context).colorScheme.primary)
        : (base?.withValues(alpha: 0.72) ?? Theme.of(context).textTheme.bodySmall?.color);

    return InkWell(
      onTap: () => context.read<LanguageProvider>().setLanguage(language),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: selected
              ? (onDark ? Colors.white : Theme.of(context).colorScheme.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          language.nativeName,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? (onDark ? Colors.deepPurple : Colors.white)
                : color,
          ),
        ),
      ),
    );
  }
}

/// Globe button for app bars / profile menus. Opens the language screen.
class LanguageIconButton extends StatelessWidget {
  const LanguageIconButton({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>().language;
    return IconButton(
      tooltip: context.tr('common.changeLanguage'),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
      ),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.translate_rounded, size: 20, color: onDark ? Colors.white : null),
          const SizedBox(width: 4),
          Text(
            language.nativeName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: onDark ? Colors.white : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile -> Settings -> Language.
///
/// Changing the radio updates the entire app immediately.
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LanguageProvider>();
    final current = provider.language;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('common.changeLanguage'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            context.tr('common.selectLanguage'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          for (final language in AppLanguage.values)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: language == current
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  width: language == current ? 1.6 : 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => provider.setLanguage(language),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        language == current
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 21,
                        color: language == current
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              language.nativeName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (language != AppLanguage.en)
                              Text(
                                language.englishName,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      Text(
                        language.code.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            context.tr('language.applyingTo', {'language': current.nativeName}),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
