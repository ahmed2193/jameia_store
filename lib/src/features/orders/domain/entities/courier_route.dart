import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';
import 'geo_metric_frame.dart';

/// The road a rider takes from the store to the customer's door, as a
/// polyline, with the arithmetic the live map needs along it: where the
/// rider is after some metres, which way the road points there, what is
/// left of it, and how far along a reported position lies — snapped onto
/// the road, so GPS noise never puts the rider in a garden.
class CourierRoute extends Equatable {
  /// [points] run from the store (first) to the door (last); a point that
  /// repeats the one before it is dropped.
  factory CourierRoute(List<GeoPointEntity> points) {
    assert(points.length >= minPoints, 'a route needs $minPoints points');
    final frame = GeoMetricFrame(points.first);
    final kept = <GeoPointEntity>[];
    final local = <math.Point<double>>[];
    final marks = <double>[];
    for (final point in points) {
      final meters = frame.toMeters(point);
      if (local.isEmpty) {
        marks.add(0);
      } else {
        final step = meters.distanceTo(local.last);
        if (step < _samePointMeters) continue;
        marks.add(marks.last + step);
      }
      kept.add(point);
      local.add(meters);
    }
    // Every point was the same one: a road of no length, still one segment.
    if (kept.length < minPoints) {
      kept.add(kept.first);
      local.add(local.first);
      marks.add(0);
    }
    final drawn = _keepMask(local);
    return CourierRoute._(
      List<GeoPointEntity>.unmodifiable(kept),
      frame,
      List<math.Point<double>>.unmodifiable(local),
      List<double>.unmodifiable(marks),
      drawn,
      List<GeoPointEntity>.unmodifiable(<GeoPointEntity>[
        for (var i = 0; i < kept.length; i++)
          if (drawn[i]) kept[i],
      ]),
    );
  }

  const CourierRoute._(
    this.points,
    this._frame,
    this._local,
    this._marks,
    this._drawn,
    this.drawPoints,
  );

  /// A road has a start and an end.
  static const int minPoints = 2;

  /// Closer than this, two points are the same corner.
  static const double _samePointMeters = 0.01;

  /// How far off the road a drawn line may cut a corner: under half a dp at
  /// the closest zoom the live map allows, so nobody can see it.
  static const double drawToleranceMeters = 0.3;

  /// The stretch of road [headingAround] reads the heading over: about
  /// 1.5 s at city pace, so the rider turns through a corner, not at it.
  static const double turnSpanMeters = 12;

  static const double _degreesPerRadian = 180 / math.pi;
  static const double _fullTurn = 360;
  static const double _halfTurn = 180;

  /// The corners of the road, store first, door last.
  final List<GeoPointEntity> points;
  final GeoMetricFrame _frame;

  /// [points] in metres around the store.
  final List<math.Point<double>> _local;

  /// Metres from the start to each of [points].
  final List<double> _marks;

  /// Which of [points] a drawn line needs: the ends, and every corner more
  /// than [drawToleranceMeters] off the straight line between its kept
  /// neighbours.
  final List<bool> _drawn;

  /// The corners a drawn line needs, store first, door last: [points]
  /// without the ones that lie (within [drawToleranceMeters]) on a straight
  /// stretch. For drawing only — the ride itself runs on [points].
  final List<GeoPointEntity> drawPoints;

  GeoPointEntity get start => points.first;
  GeoPointEntity get end => points.last;
  double get lengthMeters => _marks.last;

  /// [meters] kept on the road (0 … [lengthMeters]).
  double clamp(double meters) => meters.clamp(0, lengthMeters).toDouble();

  /// Where a rider is after [meters] of road.
  GeoPointEntity pointAt(double meters) =>
      _frame.toPoint(_localAt(clamp(meters)));

  /// Which way the road points at [meters]: a compass heading, in degrees
  /// clockwise from north (0 … 360).
  double headingAt(double meters) {
    final index = _segmentAt(clamp(meters));
    return _heading(_local[index], _local[index + 1]);
  }

  /// Which way the rider faces at [meters]: the road's heading from
  /// [span] / 2 behind to [span] / 2 ahead — each stretch's heading
  /// weighted by how much of that window it covers, averaged as an angle
  /// (each corner adding its own turn) — so they turn through a corner over
  /// [span] metres of road, at an even pace however sharp it is, instead of
  /// snapping round at the corner itself. (The line from one end of the
  /// window to the other would swing round in a metre or two where the two
  /// sides of a sharp corner nearly cancel.) Where the window is one point
  /// (a road of no length), [headingAt].
  double headingAround(double meters, {double span = turnSpanMeters}) {
    final half = span / 2;
    final from = clamp(meters - half);
    final to = clamp(meters + half);
    if (to - from < _samePointMeters) return headingAt(meters);
    final last = _marks.length - 2;
    var index = _segmentAt(from);
    var at = from;
    var sum = 0.0;
    double? previous;
    while (at < to) {
      final end = math.min(to, _marks[index + 1]);
      var heading = _heading(_local[index], _local[index + 1]);
      if (previous != null) heading = previous + _turn(heading - previous);
      sum += heading * (end - at);
      previous = heading;
      at = end;
      if (index == last) break;
      index++;
    }
    return (sum / (to - from)) % _fullTurn;
  }

  /// [degrees] as the turn it makes, -180 … 180 (exclusive).
  static double _turn(double degrees) =>
      (degrees + _halfTurn) % _fullTurn - _halfTurn;

  /// The road between [from] and [to] metres: the point at [from], every
  /// corner in between, the point at [to] — what is left ahead of a rider,
  /// or the part a line that draws itself in has drawn so far.
  List<GeoPointEntity> slice(double from, double to) {
    final start = clamp(from);
    final end = math.max(start, clamp(to));
    final last = _segmentAt(end);
    return <GeoPointEntity>[
      pointAt(start),
      for (var i = _segmentAt(start) + 1; i <= last; i++) points[i],
      pointAt(end),
    ];
  }

  /// [slice] for a line on the map: the same exact ends, so the line still
  /// starts right at the rider, with only the corners of [drawPoints] in
  /// between.
  List<GeoPointEntity> drawSlice(double from, double to) {
    final start = clamp(from);
    final end = math.max(start, clamp(to));
    final last = _segmentAt(end);
    return <GeoPointEntity>[
      pointAt(start),
      for (var i = _segmentAt(start) + 1; i <= last; i++)
        if (_drawn[i]) points[i],
      pointAt(end),
    ];
  }

  /// How far along the road [position] lies: the nearest point of the road
  /// between [from] and [to] (the road's end when `null`). A rider never
  /// drives back, so a fix that GPS noise puts behind [from] stays at
  /// [from]; the search runs forward only, so a road that passes the same
  /// corner twice is read in order; [to] keeps a rider on the leg they are
  /// on where two legs share a street.
  double project(GeoPointEntity position, {double from = 0, double? to}) {
    final start = clamp(from);
    final end = to == null ? lengthMeters : math.max(start, clamp(to));
    final target = _frame.toMeters(position);
    var best = start;
    var bestDistance = double.infinity;
    final last = math.min(_segmentAt(end), _local.length - 2);
    for (var i = _segmentAt(start); i <= last; i++) {
      final a = _local[i];
      final b = _local[i + 1];
      final length = _marks[i + 1] - _marks[i];
      final t = length == 0
          ? 0.0
          : _closestT(a, b, target)
                .clamp(
                  math.max(0.0, (start - _marks[i]) / length),
                  math.min(1.0, (end - _marks[i]) / length),
                )
                .toDouble();
      final distance = _lerp(a, b, t).squaredDistanceTo(target);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = _marks[i] + length * t;
      }
    }
    return best.clamp(start, end).toDouble();
  }

  /// The segment (`i` → `i + 1`) that holds [meters].
  int _segmentAt(double meters) {
    var low = 0;
    var high = _marks.length - 2;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (_marks[mid] <= meters) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  math.Point<double> _localAt(double meters) {
    final index = _segmentAt(meters);
    final length = _marks[index + 1] - _marks[index];
    final t = length == 0 ? 0.0 : (meters - _marks[index]) / length;
    return _lerp(_local[index], _local[index + 1], t);
  }

  static math.Point<double> _lerp(
    math.Point<double> a,
    math.Point<double> b,
    double t,
  ) => math.Point<double>(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);

  /// Where along `a → b` (0 … 1) the point nearest [p] lies.
  static double _closestT(
    math.Point<double> a,
    math.Point<double> b,
    math.Point<double> p,
  ) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / (dx * dx + dy * dy);
    return t.clamp(0, 1).toDouble();
  }

  /// Douglas-Peucker over [local], once per road, on an explicit stack (a
  /// long road never runs deep): which points a line drawn within
  /// [drawToleranceMeters] of the road needs. The ends always.
  static List<bool> _keepMask(List<math.Point<double>> local) {
    final last = local.length - 1;
    final keep = List<bool>.filled(local.length, false)
      ..[0] = true
      ..[last] = true;
    const tolerance = drawToleranceMeters * drawToleranceMeters;
    // Pairs of (first, last) indices still to simplify.
    final stack = <int>[0, last];
    while (stack.isNotEmpty) {
      final to = stack.removeLast();
      final from = stack.removeLast();
      var farthest = -1;
      var farthestDistance = tolerance;
      for (var i = from + 1; i < to; i++) {
        final distance = _squaredDistanceToSegment(
          local[from],
          local[to],
          local[i],
        );
        if (distance > farthestDistance) {
          farthest = i;
          farthestDistance = distance;
        }
      }
      if (farthest < 0) continue;
      keep[farthest] = true;
      stack.addAll(<int>[from, farthest, farthest, to]);
    }
    return List<bool>.unmodifiable(keep);
  }

  /// Squared metres from [p] to the nearest point of `a → b` (`a == b` on a
  /// road that comes back to where it started).
  static double _squaredDistanceToSegment(
    math.Point<double> a,
    math.Point<double> b,
    math.Point<double> p,
  ) {
    if (a == b) return p.squaredDistanceTo(a);
    return _lerp(a, b, _closestT(a, b, p)).squaredDistanceTo(p);
  }

  static double _heading(math.Point<double> a, math.Point<double> b) {
    final degrees = math.atan2(b.x - a.x, b.y - a.y) * _degreesPerRadian;
    return (degrees + _fullTurn) % _fullTurn;
  }

  @override
  List<Object?> get props => [points];
}
