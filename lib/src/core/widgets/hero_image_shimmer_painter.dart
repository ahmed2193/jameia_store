import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../responsive/app_size.dart';
import 'hero_shimmer_clock.dart';
import 'hero_shimmer_mask.dart';
import 'hero_shimmer_paints.dart';

/// One image shimmer tile in one pass: clip to the tile's shape → the
/// skeleton band (base → highlight → base, swept by a canvas translation) →
/// the Hero bag mark, tinted. A still frame ([clock] null) is the base and
/// the mark, no band. Geometry, the band shader and the mark's rect are
/// cached per size, and the mark's paint per tint ([HeroShimmerPaints]), so
/// [paint] allocates nothing per frame (cached paths, not `clipRRect`, whose
/// RRect is copied into a new list on every call).
///
/// The band is the skeleton's (`Skeletonized` → skeletonizer's
/// `ShimmerEffect`): stops 0.1 / 0.3 / 0.4 along a gentle diagonal from the
/// start edge, swept linearly from half a tile before the start edge to half
/// a tile past the end, mirrored in RTL.
class HeroImageShimmerPainter extends CustomPainter {
  HeroImageShimmerPainter({
    required this.clock,
    this.startUs = 0,
    required this.circular,
    required this.borderRadius,
    required this.textDirection,
    required this.baseColor,
    required this.highlightColor,
    required this.markTint,
  }) : _markPaint = HeroShimmerPaints.of(markTint),
       _basePaint = Paint()..color = baseColor,
       super(
         repaint: clock == null
             ? HeroShimmerMask.generation
             : Listenable.merge(<Listenable>[
                 clock,
                 HeroShimmerMask.generation,
               ]),
       );

  /// The shared ticker's time (`HeroShimmerClock.now`); null paints a still
  /// frame.
  final ValueListenable<int>? clock;

  /// When this tile's sweep started, on [clock].
  final int startUs;
  final bool circular;
  final BorderRadius? borderRadius;
  final TextDirection textDirection;
  final Color baseColor;
  final Color highlightColor;
  final Color markTint;

  // HeroImagePlaceholder's rule for the bag mark: 40 % of the tile's short
  // side, 16–48 dp, left out of a tile too small to hold 16.
  static const double _markShare = 0.4;
  static const double _markMin = AppSize.s16;
  static const double _markMax = AppSize.s48;

  // Where the band sits along a sweep (skeletonizer's lower / upper bound:
  // off the start edge at 0, off the end edge at 1) and its stops.
  static const double _sweepFrom = -0.5;
  static const double _sweepTo = 1.5;
  static const List<double> _stops = <double>[0.1, 0.3, 0.4];
  static const AlignmentDirectional _bandBegin = AlignmentDirectional(-1, -0.3);
  static const AlignmentDirectional _bandEnd = AlignmentDirectional(1, 0.3);

  /// The side of the bag mark in a tile of [size], or null when the tile is
  /// too small to hold it (the same rule as `HeroImagePlaceholder`).
  static double? markSideFor(Size size) {
    final double mark = size.shortestSide * _markShare;
    if (!mark.isFinite) return _markMax;
    if (mark < _markMin) return null;
    return mark > _markMax ? _markMax : mark;
  }

  final Paint _markPaint;
  final Paint _basePaint;
  final Paint _bandPaint = Paint();
  Size? _geoSize;
  Rect _rect = Rect.zero;
  Path? _clip;
  Rect? _markRect;

  void _ensureGeometry(Size size) {
    if (_geoSize == size) return;
    _geoSize = size;
    _rect = Offset.zero & size;
    final BorderRadius? corners = borderRadius;
    _clip = circular
        ? (Path()..addOval(_rect))
        : corners != null
        ? (Path()..addRRect(corners.toRRect(_rect)))
        : null;
    _bandPaint.shader = LinearGradient(
      begin: _bandBegin,
      end: _bandEnd,
      colors: <Color>[baseColor, highlightColor, baseColor],
      stops: _stops,
    ).createShader(_rect, textDirection: textDirection);
    final double? side = markSideFor(size);
    _markRect = side == null
        ? null
        : Rect.fromCenter(center: _rect.center, width: side, height: side);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _ensureGeometry(size);
    canvas.save();
    final Path? clip = _clip;
    if (clip != null) {
      canvas.clipPath(clip);
    } else {
      canvas.clipRect(_rect);
    }
    final ValueListenable<int>? time = clock;
    if (time == null) {
      canvas.drawPaint(_basePaint);
    } else {
      final double phase = HeroShimmerClock.phaseAt(startUs, time.value);
      final double at = _sweepFrom + (_sweepTo - _sweepFrom) * phase;
      final double dx = size.width * at;
      canvas.save();
      canvas.translate(textDirection == TextDirection.rtl ? -dx : dx, 0);
      canvas.drawPaint(_bandPaint);
      canvas.restore();
    }
    final HeroShimmerMaskImage? mask = HeroShimmerMask.mask;
    final Rect? markRect = _markRect;
    if (mask != null && markRect != null) {
      canvas.drawImageRect(mask.image, mask.src, markRect, _markPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(HeroImageShimmerPainter oldDelegate) =>
      oldDelegate.clock != clock ||
      oldDelegate.startUs != startUs ||
      oldDelegate.circular != circular ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.textDirection != textDirection ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightColor != highlightColor ||
      oldDelegate.markTint != markTint;
}
