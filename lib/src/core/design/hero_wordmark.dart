import 'dart:ui';

import 'hero_glyphs.dart';

/// The name under the Hero mark: "hero" in Latin, "هيرو" in Arabic, drawn
/// [unitScale] times larger so the two read the same size.
enum HeroWordmark {
  latin(unitScale: 1),
  arabic(unitScale: 1.2);

  const HeroWordmark({required this.unitScale});

  final double unitScale;

  static HeroWordmark forLanguage(String languageCode) =>
      languageCode == 'ar' ? arabic : latin;

  /// The letters, in font units at their place along the line.
  List<Path> get pieces => switch (this) {
    latin => HeroGlyphs.latin,
    arabic => HeroGlyphs.arabic,
  };

  /// Ink bounds of [pieces].
  Rect get ink => switch (this) {
    latin => HeroGlyphs.latinInk,
    arabic => HeroGlyphs.arabicInk,
  };
}
