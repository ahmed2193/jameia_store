import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Builds the KeeTa [ThemeData] for both brightnesses, carrying the [KeetaColors]
/// token bundle as a [ThemeExtension] and the [AppTextStyles] text theme.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, KeetaColors.light);
  static ThemeData get dark => _build(Brightness.dark, KeetaColors.dark);

  static ThemeData _build(Brightness brightness, KeetaColors c) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: c.brandPrimary,
      onPrimary: c.brandForeground,
      surface: c.surface,
      onSurface: c.primaryText,
      error: c.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.mediumBackground,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: AppTextStyles.textTheme.apply(
        bodyColor: c.primaryText,
        displayColor: c.primaryText,
      ),
      dividerColor: c.divider,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headingLarge.copyWith(color: c.primaryText),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.primaryText,
        unselectedItemColor: c.tertiaryText,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
