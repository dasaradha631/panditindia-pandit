import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';

/// PanditIndia design system (PDF section 9 - theme/colors from the
/// approved website UI).
class AppTheme {
  AppTheme._();

  static const String displayFamily = 'Marcellus';
  static const String bodyFamily = 'Poppins';

  /// Status bar over navy chrome (the pandit app is dark by default).
  static const SystemUiOverlayStyle darkStatus = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.navy,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static const SystemUiOverlayStyle lightStatus = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.navy,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static TextTheme _textTheme(Brightness brightness) {
    final Color base =
        brightness == Brightness.light ? AppColors.ink : AppColors.onDark;
    final Color muted = brightness == Brightness.light
        ? AppColors.muted
        : AppColors.onDarkMuted;

    const TextStyle display = TextStyle(
      fontFamily: displayFamily,
      fontSize: 30,
      height: 1.25,
      fontWeight: FontWeight.w400,
    );
    const TextStyle headline = TextStyle(
      fontFamily: displayFamily,
      fontSize: 24,
      height: 1.3,
      fontWeight: FontWeight.w400,
    );
    const TextStyle title = TextStyle(
      fontFamily: bodyFamily,
      fontSize: 17,
      height: 1.35,
      fontWeight: FontWeight.w600,
    );
    const TextStyle body = TextStyle(
      fontFamily: bodyFamily,
      fontSize: 14.5,
      height: 1.5,
      fontWeight: FontWeight.w400,
    );
    const TextStyle label = TextStyle(
      fontFamily: bodyFamily,
      fontSize: 13,
      height: 1.4,
      fontWeight: FontWeight.w500,
    );
    const TextStyle caption = TextStyle(
      fontFamily: bodyFamily,
      fontSize: 12,
      height: 1.4,
      fontWeight: FontWeight.w400,
    );

    return TextTheme(
      displayLarge: display.copyWith(fontSize: 34, color: base),
      displayMedium: display.copyWith(color: base),
      headlineLarge: headline.copyWith(fontSize: 28, color: base),
      headlineMedium: headline.copyWith(color: base),
      headlineSmall: headline.copyWith(fontSize: 20, color: base),
      titleLarge: title.copyWith(fontSize: 19, color: base),
      titleMedium: title.copyWith(color: base),
      titleSmall: title.copyWith(fontSize: 15, color: base),
      bodyLarge: body.copyWith(fontSize: 16, color: base),
      bodyMedium: body.copyWith(color: base),
      bodySmall: body.copyWith(fontSize: 13, color: muted),
      labelLarge: label.copyWith(fontSize: 15, color: base),
      labelMedium: label.copyWith(color: base),
      labelSmall: caption.copyWith(color: muted),
    );
  }

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onDark,
      secondary: AppColors.gold,
      onSecondary: AppColors.navy,
      error: AppColors.error,
      onError: AppColors.onDark,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      outline: AppColors.border,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.navy,
      fontFamily: bodyFamily,
    );

    return base.copyWith(
      textTheme: _textTheme(Brightness.light),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.onDark,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: darkStatus,
        titleTextStyle: TextStyle(
          fontFamily: bodyFamily,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.onDark,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 14,
          color: AppColors.muted,
        ),
        labelStyle: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onDark,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: bodyFamily,
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: AppColors.border),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: bodyFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: bodyFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle: const TextStyle(
          fontFamily: bodyFamily,
          fontSize: 13.5,
          color: AppColors.onDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.surface,
        ),
        checkColor: WidgetStateProperty.all(AppColors.onDark),
        side: const BorderSide(color: AppColors.border, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}
