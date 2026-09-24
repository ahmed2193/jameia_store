import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Jameia typography — `system.typography` resolved to concrete [TextStyle]s.
///
/// Source defines 5 families × 6 variants (large / largeMultiLine / medium /
/// mediumMultiLine / small / smallMultiLine). We expose the single-line variant
/// of each as the common case; multiline only differs by +1sp line height.
///
/// Body face = **Noto Sans** (theme `brand` font); RTL automatically falls back to
/// NotoSansArabicUI via [fontFamilyFallback]. Digits use **MTDigit**. Weights:
/// regular 400 / medium 500 / bold 700. Light sp values used (dark is +1sp).
class AppTextStyles {
  AppTextStyles._();

  // Jameia's Mach screens render almost all text in the Jameia brand OTF
  // (Jameia-Regular/Medium/Bold — confirmed by every bundle.css.json). Noto Sans
  // + NotoSansArabicUI are fallbacks for glyphs Jameia lacks (incl. Arabic).
  static const String fontFamily = 'Jameia';
  static const String digitFamily = 'MTDigit';
  static const List<String> _fallback = ['NotoSans', 'NotoSansArabicUI'];

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight bold = FontWeight.w700;

  static TextStyle _base(double size, FontWeight weight, double lineHeight) =>
      TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: _fallback,
        fontSize: size,
        fontWeight: weight,
        height: lineHeight / size,
        color: AppColors.primaryText,
      );

  // display
  static TextStyle get displayLarge => _base(28, medium, 37);
  static TextStyle get displayMedium => _base(23, medium, 31);
  static TextStyle get displaySmall => _base(18, medium, 24);

  // heading
  static TextStyle get headingLarge => _base(18, medium, 24);
  static TextStyle get headingMedium => _base(16, medium, 21);
  static TextStyle get headingSmall => _base(14, medium, 19);

  // subheading
  static TextStyle get subheadingLarge => _base(16, regular, 21);
  static TextStyle get subheadingMedium => _base(14, medium, 19);
  static TextStyle get subheadingSmall => _base(12, medium, 16);

  // body
  static TextStyle get bodyLarge => _base(14, regular, 19);
  static TextStyle get bodyMedium => _base(12, medium, 16);
  static TextStyle get bodySmall => _base(12, regular, 16);

  // caption
  static TextStyle get captionLarge => _base(12, regular, 16);
  static TextStyle get captionMedium => _base(10, medium, 13);
  static TextStyle get captionSmall => _base(10, regular, 13);

  /// Digit-display style (prices / counters) using MT Digital Display.
  static TextStyle digits(double size, {FontWeight weight = bold}) => TextStyle(
    fontFamily: digitFamily,
    fontSize: size,
    fontWeight: weight,
    color: AppColors.primaryText,
  );

  /// Maps the 30-role token set onto Flutter's [TextTheme] for Material widgets.
  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headingLarge,
    headlineMedium: headingMedium,
    headlineSmall: headingSmall,
    titleLarge: subheadingLarge,
    titleMedium: subheadingMedium,
    titleSmall: subheadingSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: captionLarge,
    labelMedium: captionMedium,
    labelSmall: captionSmall,
  );
}
