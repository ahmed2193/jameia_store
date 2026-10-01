import 'dart:math' as math;

import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../domain/entities/geo_metric_frame.dart';

/// The streets of a simulated ride, in metres around the door (`x` east,
/// `y` north) on a street grid turned by a random angle — all drawn from
/// the order id, so an order always gets the same streets:
///
/// [route]: store → door, four legs and three corners (the store a few
/// blocks away) — the rider sets off from the store.
class DemoCourierStreets {
  factory DemoCourierStreets(String orderId) {
    final random = math.Random(_seed(orderId));
    double pick(double min, double max) =>
        min + random.nextDouble() * (max - min);
    double side() => random.nextBool() ? 1 : -1;
    final grid = random.nextDouble() * math.pi / 2;
    // Store → door on the grid (door at 0, 0).
    final du = side() * pick(_storeMinAcross, _storeMaxAcross);
    final dv = side() * pick(_storeMinAlong, _storeMaxAlong);
    final u1 = -du * pick(_legShareMin, _legShareMax);
    final v1 = -dv * pick(_legShareMin, _legShareMax);
    math.Point<double> onMap(double u, double v) => math.Point<double>(
      u * math.cos(grid) - v * math.sin(grid),
      u * math.sin(grid) + v * math.cos(grid),
    );
    return DemoCourierStreets._(
      route: [
        onMap(du, dv),
        onMap(du + u1, dv),
        onMap(du + u1, dv + v1),
        onMap(0, dv + v1),
        onMap(0, 0),
      ],
    );
  }

  const DemoCourierStreets._({required this.route});

  // The store, in metres from the door along the grid.
  static const double _storeMinAcross = 450;
  static const double _storeMaxAcross = 900;
  static const double _storeMinAlong = 350;
  static const double _storeMaxAlong = 750;

  /// Where the first turn falls on each axis (share of the way).
  static const double _legShareMin = 0.35;
  static const double _legShareMax = 0.65;

  /// Corners are driven as arcs of this radius (less on a short leg).
  static const double _cornerRadius = 22;
  static const double _cornerRadiusShare = 0.45;
  static const int _cornerSteps = 6;

  static const int _fnvOffset = 0x811C9DC5;
  static const int _fnvPrime = 0x01000193;
  static const int _mask32 = 0xFFFFFFFF;

  /// Store → door corners; the door is the last.
  final List<math.Point<double>> route;

  /// [corners] with each inner corner driven as an arc: a quadratic curve
  /// through the corner, from [_cornerRadius] before it to as far after.
  static List<math.Point<double>> rounded(List<math.Point<double>> corners) {
    final points = <math.Point<double>>[corners.first];
    for (var i = 1; i < corners.length - 1; i++) {
      final corner = corners[i];
      final radius = math.min(
        _cornerRadius,
        _cornerRadiusShare *
            math.min(
              corner.distanceTo(corners[i - 1]),
              corner.distanceTo(corners[i + 1]),
            ),
      );
      final entry = _toward(corner, corners[i - 1], radius);
      final exit = _toward(corner, corners[i + 1], radius);
      for (var step = 0; step <= _cornerSteps; step++) {
        final t = step / _cornerSteps;
        final a = (1 - t) * (1 - t);
        final b = 2 * (1 - t) * t;
        final c = t * t;
        points.add(
          math.Point<double>(
            a * entry.x + b * corner.x + c * exit.x,
            a * entry.y + b * corner.y + c * exit.y,
          ),
        );
      }
    }
    return points..add(corners.last);
  }

  /// The point [distance] metres from [from] toward [to].
  static math.Point<double> _toward(
    math.Point<double> from,
    math.Point<double> to,
    double distance,
  ) {
    final length = from.distanceTo(to);
    if (length == 0) return from;
    final share = distance / length;
    return math.Point<double>(
      from.x + (to.x - from.x) * share,
      from.y + (to.y - from.y) * share,
    );
  }

  /// A stand-in store for an order whose branch has no usable pin:
  /// [_standInStoreMin]–[_standInStoreMax] metres from [home], in a
  /// direction drawn from the order id.
  static GeoPointEntity storeNear(GeoPointEntity home, String orderId) {
    final random = math.Random(_seed('$orderId$_storeSalt'));
    final angle = random.nextDouble() * 2 * math.pi;
    final distance = _between(random, _standInStoreMin, _standInStoreMax);
    return GeoMetricFrame(home).toPoint(
      math.Point<double>(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      ),
    );
  }

  static double _between(math.Random random, double min, double max) =>
      min + random.nextDouble() * (max - min);

  // Stand-in points for a ride on real roads, in metres.
  static const double _standInStoreMin = 900;
  static const double _standInStoreMax = 1600;
  static const String _storeSalt = '/store';

  /// FNV-1a over the id: the same order, the same streets, every run.
  static int _seed(String id) {
    var hash = _fnvOffset;
    for (final unit in id.codeUnits) {
      hash = ((hash ^ unit) * _fnvPrime) & _mask32;
    }
    return hash;
  }
}
