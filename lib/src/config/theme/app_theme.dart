import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Builds the Hero [ThemeData] for both brightnesses, carrying the [HeroColors]
/// token bundle as a [ThemeExtension] and the [AppTextStyles] text theme.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, HeroColors.light);
  static ThemeData get dark => _build(Brightness.dark, HeroColors.dark);

  static ThemeData _build(Brightness brightness, HeroColors c) {
    final scheme =
        ColorScheme.fromSeed(
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
        titleTextStyle: AppTextStyles.headingLarge.copyWith(
          color: c.primaryText,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.primaryText,
        unselectedItemColor: c.tertiaryText,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      // Every snack floats on the calm dark surface the offline banner uses;
      // the tone glyphs (`HeroSnackGlyph`) are tinted for it (docs/motion
      // §9.4 #15). The action sits at the trailing edge in the brand tint.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.offlineSurface,
        contentTextStyle: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.white,
        ),
        actionTextColor: AppColors.brandDarkBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
      // The app's own pages are `HeroPage`s with their own transitions and
      // back gestures (core/navigation); this only reaches the framework's
      // routes (the licenses page): predictive back on Android, the edge
      // swipe on iOS.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
