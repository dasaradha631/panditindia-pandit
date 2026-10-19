import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_l10n.dart';

class AppColors {
  static const Color primary = Color(0xFF021F2C);
  static const Color primaryLight = Color(0xFF063447);
  static const Color primaryDark = Color(0xFF01131C);
  static const Color secondary = Color(0xFF0D3B66);
  static const Color accent = Color(0xFFFF8C00);
  static const Color accentHover = Color(0xFFE07B00);
  static const Color accentLight = Color(0xFFFFF2E5);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF7E7B4);
  static const Color goldDark = Color(0xFF997A15);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cream = Color(0xFFFFFDF7);
  static const Color cardDark = Color(0xFF052B3D);
  static const Color textDark = Color(0xFF0B1B26);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);
  static const Color purple = Color(0xFF8B5CF6);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.cream,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

/// Booking status lookup.
///
/// [displayStatus] returns a canonical translation key so the caller can render
/// it in the active language via `context.tr(key)`. Use [displayStatusKey] when
/// no BuildContext is available.
class AppStatus {
  static String? displayStatusKey(String? raw) {
    final s = (raw ?? '').toLowerCase();
    if (s.contains('complete')) return 'status.completed';
    if (s.contains('cancel')) return 'status.cancelled';
    if (s.contains('pending_acceptance')) return 'status.pendingAcceptance';
    if (s.contains('reassignment')) return 'status.pendingReassignment';
    if (s.contains('pending')) return 'status.pending';
    if (s.contains('progress') ||
        s.contains('route') ||
        s.contains('arrived') ||
        s.contains('aarti') ||
        s.contains('live')) {
      return 'status.inProgress';
    }
    if (s.contains('confirm') || s.contains('accept')) return 'status.confirmed';
    return null;
  }

  static String displayStatus(String? raw, [AppL10n? l10n]) {
    final key = displayStatusKey(raw);
    if (key == null) {
      final s = (raw ?? '').trim();
      return s.isEmpty ? (l10n?.t('status.pending') ?? 'Pending') : s;
    }
    return l10n?.t(key) ?? _englishFallback[key]!;
  }

  static const Map<String, String> _englishFallback = {
    'status.completed': 'Completed',
    'status.cancelled': 'Cancelled',
    'status.pendingAcceptance': 'Pending Acceptance',
    'status.pendingReassignment': 'Pending Reassignment',
    'status.pending': 'Pending',
    'status.inProgress': 'In Progress',
    'status.confirmed': 'Confirmed',
  };

  static Color colorFor(String? raw) {
    switch (displayStatusKey(raw)) {
      case 'status.completed':
        return AppColors.success;
      case 'status.cancelled':
        return AppColors.danger;
      case 'status.confirmed':
        return AppColors.info;
      case 'status.inProgress':
        return AppColors.warning;
      default:
        return AppColors.warning;
    }
  }

  static String normalizeBookingId(dynamic id) {
    final s = id.toString();
    final matches = RegExp(r'\d+').allMatches(s).toList();
    if (matches.isEmpty) return s;
    return matches.last.group(0)!;
  }

  static String displayBookingId(dynamic id) {
    final s = id.toString();
    if (s.contains('#')) return s;
    return '#PI-2026-${normalizeBookingId(s)}';
  }
}

class Fmt {
  static final NumberFormat _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static String inr(dynamic value) {
    final n = parseAmount(value);
    return _inr.format(n);
  }

  static double parseAmount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final cleaned = value.toString().replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  /// The active language code, used to localize dates and relative times.
  static String _tag(AppL10n? l10n) => l10n?.locale.languageCode ?? 'en';

  /// Formats any stored date (ISO `2026-06-01`, day-first `01/06/2026`, or
  /// month-name `01/June/2026`) as `01/June/2026`. Unparseable values pass
  /// through unchanged.
  static String date(String? iso, [AppL10n? l10n]) {
    if (iso == null || iso.isEmpty) return '-';
    final d = _parseDate(iso);
    if (d == null) return iso;
    return DateFormat('dd/MMMM/yyyy', _tag(l10n)).format(d);
  }

  static String dateShort(String? iso, [AppL10n? l10n]) => date(iso, l10n);

  static DateTime? _parseDate(String raw) {
    final trimmed = raw.trim();
    final d = DateTime.tryParse(trimmed);
    if (d != null) return d;
    return DateTime.tryParse(dobToIso(trimmed));
  }

  /// Editable DOB fields display `15-october-2026` (D-MMMM-YYYY, lowercase
  /// full month name) — the mobile display format. Storage stays strict ISO
  /// (`1985-05-15`). Tolerates legacy `15-May-1985`, `15/05/1985` or ISO
  /// values and converts them too; [dobToIso] parses the output back.
  static String dobInput(String? iso) {
    if (iso == null || iso.trim().isEmpty) return '';
    final raw = iso.trim();
    final d = DateTime.tryParse(raw) ?? DateTime.tryParse(dobToIso(raw));
    if (d == null) return raw;
    return DateFormat('d-MMMM-yyyy', 'en').format(d).toLowerCase();
  }

  /// Parses `15-october-2026`, `15-May-1985`, `15/05/1985` (or an existing
  /// ISO value) back to `YYYY-MM-DD`.
  static String dobToIso(String value) {
    final v = value.trim();
    if (v.isEmpty) return '';
    final parsed = DateTime.tryParse(v);
    if (parsed != null) {
      return '${parsed.year.toString().padLeft(4, '0')}-'
          '${parsed.month.toString().padLeft(2, '0')}-'
          '${parsed.day.toString().padLeft(2, '0')}';
    }
    final m = RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})$').firstMatch(v);
    if (m != null) {
      final day = int.tryParse(m[1]!);
      final month = int.tryParse(m[2]!);
      if (day != null && month != null && day >= 1 && day <= 31 && month >= 1 && month <= 12) {
        return '${m[3]}-${month.toString().padLeft(2, '0')}'
            '-${day.toString().padLeft(2, '0')}';
      }
    }
    final n =
        RegExp(r'^(\d{1,2})[/\-]([A-Za-z]{3,})[/\-](\d{4})$').firstMatch(v);
    if (n != null) {
      final day = int.tryParse(n[1]!);
      final month = _monthFrom(n[2]!);
      if (day != null && day >= 1 && day <= 31 && month >= 1) {
        return '${n[3]}-${month.toString().padLeft(2, '0')}'
            '-${day.toString().padLeft(2, '0')}';
      }
    }
    return v;
  }

  /// Matches `june`, `Jun`, `JUNE` … against [_monthNames]; 0 when unknown.
  static int _monthFrom(String name) {
    final n = name.toLowerCase();
    for (var i = 0; i < _monthNames.length; i++) {
      if (_monthNames[i].startsWith(n)) return i + 1;
    }
    return 0;
  }

  static const List<String> _monthNames = [
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
  ];

  static String timeSlotLabel(String? slot) {
    if (slot == null || slot.isEmpty) return '-';
    return slot;
  }

  static String relative(String? iso, [AppL10n? l10n]) {
    if (iso == null || iso.isEmpty) return '';
    // Backend timestamps sometimes arrive as `2026-10-09 15:30` (space
    // separator) or day-first dates — normalize before giving up.
    final d = DateTime.tryParse(iso) ??
        DateTime.tryParse(iso.replaceFirst(' ', 'T'));
    if (d == null) return date(iso, l10n);
    final diff = DateTime.now().difference(d);
    String t(String key, Map<String, dynamic> p) =>
        l10n?.t(key, p) ?? '${p['count']}${_enSuffix[key]!}';
    if (diff.inMinutes < 1) return l10n?.t('time.justNow') ?? 'just now';
    if (diff.inMinutes < 60) return t('time.minutesAgo', {'count': diff.inMinutes});
    if (diff.inHours < 24) return t('time.hoursAgo', {'count': diff.inHours});
    if (diff.inDays < 7) return t('time.daysAgo', {'count': diff.inDays});
    return dateShort(iso, l10n);
  }

  static const Map<String, String> _enSuffix = {
    'time.minutesAgo': 'm ago',
    'time.hoursAgo': 'h ago',
    'time.daysAgo': 'd ago',
  };
}
