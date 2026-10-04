import 'dart:math' as math;

import 'live_map_camera.dart';

/// Whether a moment of the ride is worth a round of platform messages to
/// the native map — each carries the rider's bitmap, and a recut road every
/// point of the road left — so the map is only told what can be SEEN, at
/// the zoom the camera last settled at.
abstract final class LiveMapFrameGate {
  /// Map updates at most this often: two vsyncs at 60 Hz, three at 90,
  /// four at 120 — an even beat on every display.
  static const Duration frameGap = Duration(milliseconds: 30);

  /// …or, while the camera rides along, this often — every glide frame up
  /// to it, moved or not: the whole map moves and turns then, and a map
  /// stepped by the rider's half dp or two degrees ticks round a corner in
  /// jumps (the far edge of a turning map moves tens of dp a step). Every
  /// vsync at 60 Hz, every other one at 90 and 120.
  static const Duration chaseFrameGap = Duration(milliseconds: 16);

  /// A glide frame is sent once the rider has moved this far on screen…
  static const double minStepDp = 0.5;

  /// …or turned this much.
  static const double minTurnDegrees = 2;
  static const double _halfTurn = 180;
  static const double _fullTurn = 360;

  /// The eaten road is recut once the rider has moved this far on screen
  /// (the cut hides under the rider's icon)…
  static const double lineStepDp = 8;

  /// …and never for less than this many metres (close in).
  static const double lineStepMinMeters = 6;

  /// Whether the rider, shown at [shownMeters] facing [shownHeading], now
  /// at [meters] facing [heading], has visibly moved or turned at [zoom]
  /// and [latitude].
  static bool riderMoved({
    required double shownMeters,
    required double shownHeading,
    required double meters,
    required double heading,
    required double zoom,
    required double latitude,
  }) {
    final turn = (heading - shownHeading).abs() % _fullTurn;
    final turned =
        (turn > _halfTurn ? _fullTurn - turn : turn) >= minTurnDegrees;
    return turned ||
        (meters - shownMeters).abs() >=
            minStepDp * LiveMapCamera.metersPerDp(zoom, latitude);
  }

  /// Metres the rider moves between two cuts of the eaten road.
  static double lineStepMeters(double zoom, double latitude) => math.max(
    lineStepMinMeters,
    lineStepDp * LiveMapCamera.metersPerDp(zoom, latitude),
  );

  /// Whether a frame at [now] comes too soon after the one at [last], frames
  /// [gap] apart at the most.
  static bool tooSoon(Duration last, Duration now, {Duration gap = frameGap}) =>
      now - last < gap;
}
