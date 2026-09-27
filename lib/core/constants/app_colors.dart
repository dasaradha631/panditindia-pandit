import 'package:flutter/material.dart';

/// PanditIndia design palette (reference design board): deep navy chrome,
/// Vedic orange accent and clean surfaces.
class AppColors {
  AppColors._();

  // Primary - Vedic orange
  static const Color primary = Color(0xFFF97316);
  static const Color primaryDark = Color(0xFFEA580C);
  static const Color primarySoft = Color(0xFFFFF1E3);
  static const Color primaryBorder = Color(0xFFFFE3C8);

  // Brand darks - deep navy chrome used by the pandit screens
  static const Color navy = Color(0xFF0B1B2B);
  static const Color navySoft = Color(0xFF14324A);
  static const Color teal = Color(0xFF0E2A33);
  static const Color maroon = Color(0xFF5C0F1E);

  // Surfaces - white content pages with soft neutral fills
  static const Color cream = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF4F6F8);
  static const Color border = Color(0xFFE7EAF0);

  // Text
  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF6B7280);
  static const Color onDark = Color(0xFFFFFFFF);
  static const Color onDarkMuted = Color(0xFFD9DEE6);

  // Accents
  static const Color gold = Color(0xFFD4A24A);
  static const Color success = Color(0xFF1F9D55);
  static const Color error = Color(0xFFD64545);
  static const Color info = Color(0xFF2563EB);

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[navy, navySoft],
  );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[maroon, Color(0xFF7A1A2C)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primary, Color(0xFFFFA043)],
  );
}
