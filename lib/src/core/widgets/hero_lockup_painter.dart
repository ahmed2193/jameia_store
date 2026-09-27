import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

import '../design/hero_glyphs.dart';
import '../design/hero_mark.dart';
import '../design/hero_mark_idle.dart';
import '../design/hero_mark_painting.dart';
import '../design/hero_wordmark.dart';

/// Paints the Hero lockup — the bag in its cape standing over the name —
/// centred in its box: the name's Latin ink is [wordHeight] tall, the mark
/// [markToWord] times that, [gapToWord] of it above the name, and the bag
/// itself (not the cape flowing off it) centred over the name, as on the
/// splash. The mark is at ease at [idle] (`HeroMarkIdle`).
class HeroLockupPainter extends CustomPainter {
  HeroLockupPainter({
    required this.idle,
    required this.wordHeight,
    required this.wordmark,
    required this.markColors,
    required this.wordColor,
  }) : super(repaint: idle);

  static const double markToWord = 2;
  static const double gapToWord = 0.3;

  final Animation<double> idle;
  final double wordHeight;
  final HeroWordmark wordmark;
  final HeroMarkColors markColors;
  final Color wordColor;

  /// The box a lockup with a [wordHeight]-tall name needs.
  static Size sizeFor(double wordHeight, HeroWordmark wordmark) {
    final (:markUnit, :wordScale) = _scales(wordHeight, wordmark);
    final bounds = HeroMark.bounds;
    final bagShift = (HeroMark.bagCenter.dx - bounds.center.dx).abs();
    final markWidth = (bounds.width + 2 * bagShift) * markUnit;
    final wordWidth = wordmark.ink.width * wordScale;
    final height =
        bounds.height * markUnit +
        wordHeight * gapToWord +
        wordmark.ink.height * wordScale;
    return Size(markWidth > wordWidth ? markWidth : wordWidth, height);
  }

  static ({double markUnit, double wordScale}) _scales(
    double wordHeight,
    HeroWordmark wordmark,
  ) => (
    markUnit: wordHeight * markToWord / HeroMark.bounds.height,
    wordScale: wordHeight / HeroGlyphs.latinInk.height * wordmark.unitScale,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final (:markUnit, :wordScale) = _scales(wordHeight, wordmark);
    final bounds = HeroMark.bounds;
    final ink = wordmark.ink;
    final markHeight = bounds.height * markUnit;
    final gap = wordHeight * gapToWord;
    final total = markHeight + gap + ink.height * wordScale;
    final top = (size.height - total) / 2;
    final middle = size.width / 2;
    final bagShift = (HeroMark.bagCenter.dx - bounds.center.dx) * markUnit;
    HeroMarkPainting.paint(
      canvas,
      center: Offset(middle - bagShift, top + markHeight / 2),
      unit: markUnit,
      colors: markColors,
      pose: HeroMarkIdle.poseAt(idle.value),
    );
    final wordTop = top + markHeight + gap;
    final letters = Paint()..color = wordColor;
    canvas
      ..save()
      ..translate(
        middle - ink.center.dx * wordScale,
        wordTop - ink.top * wordScale,
      )
      ..scale(wordScale);
    for (final piece in wordmark.pieces) {
      canvas.drawPath(piece, letters);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HeroLockupPainter old) =>
      old.idle != idle ||
      old.wordHeight != wordHeight ||
      old.wordmark != wordmark ||
      old.markColors != markColors ||
      old.wordColor != wordColor;
}
