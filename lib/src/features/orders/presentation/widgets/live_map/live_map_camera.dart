import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../../core/widgets/hero_map.dart';
import '../../../domain/entities/courier_stage.dart';
import '../../../domain/entities/courier_trip.dart';

/// Where the live map's camera looks, the way delivery apps frame a ride:
/// the whole ride first; then, while it follows, the road left from the
/// rider to where they are heading — the store, then the door — so every
/// bend ahead stays in view and the view closes in as they get near; at the
/// door, the door, close up. Between those steps the camera holds still
/// ([shouldReframe]): the rider glides across a steady map instead of the
/// map breathing on every ping.
abstract final class LiveMapCamera {
  /// Room around the framed points, inside the map's own padding.
  static const double framePadding = AppSpacing.s48;

  /// Room left between a pin's art and the frame's edge.
  static const double _pinClearance = AppSpacing.s8;

  /// Closer than this (metres of road), two points are framed as one spot.
  static const double _oneSpotMeters = 80;

  /// The zoom of one spot, and the closest the camera ever goes.
  static const double spotZoom = 17;
  static const double maxZoom = 17.5;

  static const MinMaxZoomPreference zoomRange = MinMaxZoomPreference(
    null,
    maxZoom,
  );

  /// The camera re-aims once the road left has shrunk to this share of
  /// what it was when it last aimed — about half a zoom level closer.
  static const double reframeShare = 0.7;

  /// The zoom the map opens at, before the ride is framed.
  static const double openingZoom = 14.5;

  /// Metres of ground in one logical pixel at zoom 0 on the equator (the
  /// world is 256 logical pixels wide there).
  static const double _metersPerDpAtZoom0 = 156543.03392;
  static const double _radiansPerDegree = math.pi / 180;

  static LatLng latLng(GeoPointEntity point) => LatLng(point.lat, point.lng);

  /// Metres of ground one logical pixel covers at [zoom] and [latitude].
  static double metersPerDp(double zoom, double latitude) =>
      _metersPerDpAtZoom0 *
      math.cos(latitude * _radiansPerDegree) /
      math.pow(2, zoom);

  /// The room around the framed points for a pin of [size] (logical
  /// pixels) that marks its point at [anchor]: [framePadding], or more when
  /// the pin reaches further from its point — the store's name bubble —
  /// so a pin at the frame's edge never crosses the screen's edge.
  static double framePaddingFor(Size size, Offset anchor) => math.max(
    framePadding,
    math.max(size.width / 2, anchor.dy * size.height) + _pinClearance,
  );

  /// [edge], capped so the framed points keep at least half of the
  /// [visible] map's shorter side: a fit whose room leaves no map at all
  /// fails (Android: "View size is too small after padding is applied") and
  /// the camera would not move — a small phone at a large text size.
  static double fitEdge(double edge, Size visible) =>
      math.max(0, math.min(edge, visible.shortestSide * _edgeShareMax));

  /// The most of the visible map's shorter side one edge's room may take.
  static const double _edgeShareMax = 0.25;

  /// The ride at a glance: where the rider sets off, the store, the door;
  /// [padding] room around them ([framePaddingFor]).
  static CameraUpdate overview(
    CourierTrip trip, {
    double padding = framePadding,
  }) => _frame([trip.path.start, trip.store, trip.home], padding);

  /// Following a rider [riderMeters] down the trip's path at [stage];
  /// [padding] room around what is framed ([framePaddingFor]).
  static CameraUpdate follow(
    CourierTrip trip,
    double riderMeters,
    CourierStage stage, {
    double padding = framePadding,
  }) {
    final left = leftMeters(trip, riderMeters, stage);
    return switch (stage) {
      CourierStage.assigning => overview(trip, padding: padding),
      CourierStage.toStore =>
        left < _oneSpotMeters
            ? _spot(trip.store)
            : _frame(
                trip.path.slice(riderMeters, trip.deliveryStartMeters),
                padding,
              ),
      CourierStage.atStore => _frame([trip.store, trip.home], padding),
      CourierStage.onTheWay || CourierStage.nearby =>
        left < _oneSpotMeters
            ? _spot(trip.home)
            : _frame([
                ...trip.path.slice(riderMeters, trip.path.lengthMeters),
                trip.home,
              ], padding),
      CourierStage.arrived => _spot(trip.home),
    };
  }

  /// Metres of road from the rider to where [stage] heads: the store, then
  /// the door; none while the ride stands (being found, at the store, at
  /// the door).
  static double leftMeters(
    CourierTrip trip,
    double riderMeters,
    CourierStage stage,
  ) => switch (stage) {
    CourierStage.toStore => math.max(
      0.0,
      trip.deliveryStartMeters - riderMeters,
    ),
    CourierStage.onTheWay ||
    CourierStage.nearby => math.max(0.0, trip.path.lengthMeters - riderMeters),
    _ => 0,
  };

  /// Whether the camera re-aims within a stage, [aimedLeft] metres of road
  /// having been left when it last aimed and [left] now: once the road left
  /// has shrunk to [reframeShare] of it, or the rider comes within one spot
  /// of the goal (the close-up) — never again after that, nor while the
  /// ride stands. A new stage always re-aims (the caller's call).
  static bool shouldReframe({
    required double aimedLeft,
    required double left,
  }) =>
      aimedLeft >= _oneSpotMeters &&
      (left <= aimedLeft * reframeShare || left < _oneSpotMeters);

  static CameraUpdate _spot(GeoPointEntity point) =>
      CameraUpdate.newLatLngZoom(latLng(point), spotZoom);

  static CameraUpdate _frame(List<GeoPointEntity> points, double padding) {
    var south = points.first.lat;
    var north = south;
    var west = points.first.lng;
    var east = west;
    for (final point in points.skip(1)) {
      south = math.min(south, point.lat);
      north = math.max(north, point.lat);
      west = math.min(west, point.lng);
      east = math.max(east, point.lng);
    }
    return CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(south, west),
        northeast: LatLng(north, east),
      ),
      padding,
    );
  }
}
