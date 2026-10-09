import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../motion/keyframe_track.dart';

/// One moving layer of a state illustration ([StateArt]): its SVG — drawn in
/// the plate's own 160 × 120 frame, so the layers stack exactly — and how it
/// moves over one lap of the plate's loop. Every track starts and ends on the
/// part as drawn, so the plate at rest (reduced motion, off screen, a screen
/// reader, the budget spent) is the still sticker.
///
/// Lengths are plate units (one unit = 1 dp on the 160 dp plate), angles are
/// degrees clockwise; the part turns and scales around [pivot].
@immutable
class StateArtPart {
  const StateArtPart(
    this.asset, {
    this.pivot = Offset.zero,
    this.turn,
    this.dx,
    this.dy,
    this.scale,
    this.opacity,
  });

  /// A `HeroAssets` path.
  final String asset;
  final Offset pivot;
  final KeyframeTrack? turn;
  final KeyframeTrack? dx;
  final KeyframeTrack? dy;
  final KeyframeTrack? scale;

  /// Fades the part; a part whose track rests at 0 only shows mid-story.
  final KeyframeTrack? opacity;

  static const double _degreesPerHalfTurn = 180;

  /// Whether the part moves (beyond fading).
  bool get moves => turn != null || dx != null || dy != null || scale != null;

  /// The part's transform at lap position [t] on a plate drawn [unit]
  /// logical pixels per plate unit: scaled and turned around [pivot], then
  /// shifted.
  Matrix4 transformAt(double t, double unit) {
    final radians = (turn?.transform(t) ?? 0) * math.pi / _degreesPerHalfTurn;
    final factor = scale?.transform(t) ?? 1;
    final cos = math.cos(radians) * factor;
    final sin = math.sin(radians) * factor;
    final px = pivot.dx * unit;
    final py = pivot.dy * unit;
    final tx = (dx?.transform(t) ?? 0) * unit + px - (cos * px - sin * py);
    final ty = (dy?.transform(t) ?? 0) * unit + py - (sin * px + cos * py);
    return Matrix4(cos, sin, 0, 0, -sin, cos, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);
  }
}
