import 'dart:ui';

import '../../../../core/design/hero_glyphs.dart';

/// The name the splash assembles under the mark, in the app's language:
/// "hero" or "هيرو". The bag delivers it piece by piece: a letter at a time,
/// or a joined run of Arabic letters at a time.
enum SplashWordmark {
  latin(unitScale: 1, stagger: 80),

  /// Arabic letters read smaller per em than Fredoka's, and come in two
  /// joined runs, so they are drawn larger and delivered further apart.
  arabic(unitScale: 1.2, stagger: 150);

  const SplashWordmark({required this.unitScale, required this.stagger});

  /// Size against the Latin name.
  final double unitScale;

  /// Time between two deliveries, in ms.
  final double stagger;

  /// The pieces in delivery (reading) order, in font units.
  List<Path> get pieces => switch (this) {
    latin => HeroGlyphs.latin,
    arabic => HeroGlyphs.arabic,
  };

  /// Ink bounds of each piece, in the order of [pieces].
  List<Rect> get pieceBounds => switch (this) {
    latin => _latinBounds,
    arabic => _arabicBounds,
  };

  /// Ink bounds of the whole name.
  Rect get ink => switch (this) {
    latin => HeroGlyphs.latinInk,
    arabic => HeroGlyphs.arabicInk,
  };

  static final List<Rect> _latinBounds = [
    for (final piece in HeroGlyphs.latin) piece.getBounds(),
  ];
  static final List<Rect> _arabicBounds = [
    for (final piece in HeroGlyphs.arabic) piece.getBounds(),
  ];

  /// The name for an app language.
  static SplashWordmark forLanguage(String languageCode) =>
      languageCode == 'ar' ? arabic : latin;
}
