import 'dart:ui';

import '../../../../core/design/hero_glyphs.dart';
import '../../../../core/design/hero_mark.dart';
import 'splash_wordmark.dart';

/// Screen geometry of the splash for one screen [size] and name: where the
/// mark sits on the launch screen (the native frame), and where the finished
/// lockup — the bag over the name — and the tagline end up.
class SplashLayout {
  factory SplashLayout(Size size, SplashWordmark wordmark) {
    final center = size.center(Offset.zero);
    final latinHeight = (size.width * wordHeightFraction).clamp(
      minWordHeight,
      maxWordHeight,
    );
    final wordScale =
        latinHeight / HeroGlyphs.latinInk.height * wordmark.unitScale;
    final ink = wordmark.ink;
    final wordHeight = ink.height * wordScale;
    final markUnit = latinHeight * markToWord / HeroMark.bounds.height;
    final markHeight = HeroMark.bounds.height * markUnit;
    final gap = latinHeight * gapToWord;
    final top =
        center.dy - lockupLift - (markHeight + gap + wordHeight) / 2;
    final wordTop = top + markHeight + gap;
    // The bag itself — not the cape flowing off it — stands over the name.
    final bagShift = (HeroMark.bagCenter.dx - HeroMark.bounds.center.dx) * markUnit;
    return SplashLayout._(
      size: size,
      wordmark: wordmark,
      center: center,
      markCenter: Offset(center.dx - bagShift, top + markHeight / 2),
      markUnit: markUnit,
      wordScale: wordScale,
      wordOrigin: Offset(
        center.dx - ink.center.dx * wordScale,
        wordTop - ink.top * wordScale,
      ),
      wordBottom: wordTop + wordHeight,
      // The centre's distance from the top-left corner = half the diagonal.
      burstRadius: center.distance,
    );
  }

  const SplashLayout._({
    required this.size,
    required this.wordmark,
    required this.center,
    required this.markCenter,
    required this.markUnit,
    required this.wordScale,
    required this.wordOrigin,
    required this.wordBottom,
    required this.burstRadius,
  });

  /// Android 12+ shows the launch image (1152 px, read as 4×) in a 288 dp
  /// box centred on the screen; iOS and older Android show the same image at
  /// the same size.
  static const double nativeBox = 288;

  /// Radius of the circle Android 12+ keeps of that box (768 px at 4×).
  static const double nativeSafeRadius = 96;

  /// dp per mark design unit on the launch screen: the mark is about 150 dp
  /// wide and its farthest point stays clear of [nativeSafeRadius].
  static const double nativeUnit = 1.7;

  /// Height of the Latin name's ink as a share of the screen width, kept
  /// between [minWordHeight] and [maxWordHeight] dp.
  static const double wordHeightFraction = 0.14;
  static const double minWordHeight = 40;
  static const double maxWordHeight = 56;

  /// The mark stands this many times the name's height, this far above it.
  static const double markToWord = 2;
  static const double gapToWord = 0.3;

  /// The lockup sits this far above the centre so it and the tagline under
  /// it read as one centred group.
  static const double lockupLift = 16;
  static const double taglineGap = 22;

  final Size size;
  final SplashWordmark wordmark;
  final Offset center;

  /// Where the mark's bounds centre and size (dp per design unit) end up in
  /// the lockup.
  final Offset markCenter;
  final double markUnit;

  /// dp per font unit of the name, and the screen position of its font
  /// origin (first pen, baseline).
  final double wordScale;
  final Offset wordOrigin;

  /// Bottom of the name's ink.
  final double wordBottom;

  /// Distance from [center] to a screen corner: the burst disc covers the
  /// whole screen at this radius.
  final double burstRadius;

  /// Where the mark sits on the launch screen: centred, [nativeUnit] big.
  Offset get nativeMarkCenter => center;

  /// Top of the tagline, under the name.
  double get taglineTop => wordBottom + taglineGap;

  /// Where the mark's bottom middle is on the launch screen / in the lockup.
  Offset get nativeGround => groundOf(nativeMarkCenter, nativeUnit);
  Offset get lockupGround => groundOf(markCenter, markUnit);

  /// Screen centre of piece [index] of the name once delivered.
  Offset pieceCenter(int index) =>
      wordOrigin + wordmark.pieceBounds[index].center * wordScale;

  /// Middle of the delivered name.
  Offset get wordCenter => wordOrigin + wordmark.ink.center * wordScale;

  /// Everything the finished lockup paints: the mark and the name.
  Rect get lockupBounds {
    final b = HeroMark.bounds;
    final mark = Rect.fromCenter(
      center: markCenter,
      width: b.width * markUnit,
      height: b.height * markUnit,
    );
    final ink = wordmark.ink;
    final word = Rect.fromLTRB(
      wordOrigin.dx + ink.left * wordScale,
      wordOrigin.dy + ink.top * wordScale,
      wordOrigin.dx + ink.right * wordScale,
      wordBottom,
    );
    return mark.expandToInclude(word);
  }

  /// Screen point of the mark's [point] (design units) for a mark centred at
  /// [markCenter] at [unit] dp per unit.
  static Offset pointOf(Offset point, Offset markCenter, double unit) =>
      markCenter + (point - HeroMark.bounds.center) * unit;

  static Offset groundOf(Offset markCenter, double unit) =>
      pointOf(HeroMark.ground, markCenter, unit);

  static Offset openingOf(Offset markCenter, double unit) =>
      pointOf(HeroMark.opening, markCenter, unit);

  /// Largest distance from the centre the launch-screen mark paints to.
  static double get nativeReach => HeroMark.reach * nativeUnit;
}
