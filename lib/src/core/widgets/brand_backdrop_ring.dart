import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../design/grocery_doodles.dart';

/// The groceries a brand backdrop lays around the logo: a seeded scatter over
/// a ring sized to the header band they frame, so every page shows the same
/// spread and a header handed from one page to the next looks the same. The
/// ring is recorded once per band size as a [ui.Picture], centred on the
/// origin, which the painter only turns and scales every frame.
class BrandBackdropRing {
  /// A fixed seed: the same spread every time.
  static const int _seed = 11;

  /// Ring radii, the least distance between two groceries and their size
  /// range, as shares of the band's half diagonal. The inner radius keeps
  /// the logo clear; the outer one reaches past the band's corners, so the
  /// edges stay framed whichever way the spread has turned.
  static const double _innerShare = 0.54;
  static const double _outerShare = 1.07;
  static const double _gapShare = 0.255;
  static const double _minSizeShare = 0.21;
  static const double _sizeRangeShare = 0.11;

  /// Most groceries, and how many places are tried to fit them.
  static const int _maxItems = 32;
  static const int _attempts = 4000;

  /// Step between the kinds of two groceries placed one after the other
  /// (coprime with the number of kinds, so neighbours differ).
  static const int _kindStep = 5;

  static const int _lcgMultiplier = 16807;
  static const int _lcgModulus = 2147483647;

  ui.Picture? _picture;
  Size? _band;

  /// The spread for a header band of [band] size.
  ui.Picture pictureFor(Size band) {
    final cached = _picture;
    if (cached != null && band == _band) return cached;
    cached?.dispose();
    final picture = _record(band);
    _picture = picture;
    _band = band;
    return picture;
  }

  void dispose() {
    _picture?.dispose();
    _picture = null;
    _band = null;
  }

  static ui.Picture _record(Size band) {
    final reach = band.center(Offset.zero).distance;
    final inner = reach * _innerShare;
    final outer = reach * _outerShare;
    final gap = reach * _gapShare;
    var state = _seed;
    double next() {
      state = (state * _lcgMultiplier) % _lcgModulus;
      return state / _lcgModulus;
    }

    const kinds = GroceryDoodle.values;
    final placed =
        <({Offset at, GroceryDoodle kind, double turn, double side})>[];
    for (
      var attempt = 0;
      attempt < _attempts && placed.length < _maxItems;
      attempt++
    ) {
      final angle = next() * 2 * math.pi;
      final radius = math.sqrt(
        inner * inner + next() * (outer * outer - inner * inner),
      );
      final at = Offset(radius * math.cos(angle), radius * math.sin(angle));
      final turn = next() * 2 * math.pi;
      final side = reach * (_minSizeShare + next() * _sizeRangeShare);
      if (placed.any((item) => (item.at - at).distance < gap)) continue;
      placed.add((
        at: at,
        kind: kinds[(placed.length * _kindStep) % kinds.length],
        turn: turn,
        side: side,
      ));
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = GroceryDoodlePainting.center;
    for (final item in placed) {
      final scale = item.side / GroceryDoodlePainting.box;
      canvas
        ..save()
        ..translate(item.at.dx, item.at.dy)
        ..rotate(item.turn)
        ..scale(scale)
        ..translate(-center.dx, -center.dy);
      GroceryDoodlePainting.paint(canvas, item.kind);
      canvas.restore();
    }
    return recorder.endRecording();
  }
}
