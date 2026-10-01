import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../../../../core/widgets/hero_map.dart';
import '../../../domain/entities/courier_route.dart';
import '../../../domain/entities/courier_stage.dart';
import '../../../domain/entities/courier_trip.dart';
import '../../../domain/entities/geo_metric_frame.dart';
import 'live_map_camera.dart';

/// The camera riding along with the rider, the way Google Maps follows a
/// car in its driving view: close in, leaning towards the road ahead,
/// turned so that road runs up the screen, the rider low in the part of
/// the map left in view, so most of it is the road they are about to take.
/// Over the last stretch to where they are heading (the store, then the
/// door) it closes in further.
///
/// Every value comes from where the rider is on the road and the room the
/// map has — none from the clock — so, fed the rider's glide frame by
/// frame, the camera moves exactly as smoothly as the rider and stops the
/// moment they stop.
abstract final class LiveMapChaseCamera {
  /// How far the camera leans from looking straight down (degrees).
  static const double tilt = 45;

  /// The zoom on the road…
  static const double cruiseZoom = 16.75;

  /// …closing in to this one over the last [closeInMeters] of road to the
  /// goal.
  static const double goalZoom = LiveMapCamera.maxZoom;
  static const double closeInMeters = 250;

  /// Where the rider shows in the part of the map left in view: 0 at its
  /// top edge, 1 at its foot.
  static const double riderShare = 0.7;

  /// The native camera's vertical field of view (degrees): how much larger
  /// the tilted ground nearer the camera shows.
  static const double fieldOfView = 25;

  /// The map turns with the road read from this far behind the rider to as
  /// far ahead as the rider's own turn reads
  /// ([CourierRoute.turnSpanMeters]): a touch calmer than the rider, so
  /// they lean into a corner and the road comes round after them.
  static const double _turnBehindMeters = 10;
  static const double _turnAheadMeters = CourierRoute.turnSpanMeters / 2;

  /// The middle of the map's visible part, where the camera's target shows.
  static const double _middle = 0.5;
  static const double _radiansPerDegree = math.pi / 180;

  /// The camera for a rider [riderMeters] down the trip's path at [stage],
  /// on a [map] whose [padding] the top bar and the panel cover.
  static CameraPosition position(
    CourierTrip trip,
    double riderMeters,
    CourierStage stage, {
    required Size map,
    required EdgeInsets padding,
  }) {
    final path = trip.path;
    final rider = path.pointAt(riderMeters);
    final bearing = bearingAt(path, riderMeters);
    final zoom = zoomFor(LiveMapCamera.leftMeters(trip, riderMeters, stage));
    final lead = leadMeters(
      metersPerDp: LiveMapCamera.metersPerDp(zoom, rider.lat),
      map: map,
      padding: padding,
    );
    final heading = bearing * _radiansPerDegree;
    final target = GeoMetricFrame(rider).toPoint(
      math.Point<double>(lead * math.sin(heading), lead * math.cos(heading)),
    );
    return CameraPosition(
      target: LiveMapCamera.latLng(target),
      zoom: zoom,
      bearing: bearing,
      tilt: tilt,
    );
  }

  /// Which way the map is turned with a rider [meters] down [path]: a
  /// compass heading, degrees clockwise from north.
  static double bearingAt(CourierRoute path, double meters) =>
      path.headingAround(
        meters + (_turnAheadMeters - _turnBehindMeters) / 2,
        span: _turnAheadMeters + _turnBehindMeters,
      );

  /// The zoom with [left] metres of road to the goal: [cruiseZoom], easing
  /// in to [goalZoom] over the last [closeInMeters].
  static double zoomFor(double left) {
    final near = (1 - left / closeInMeters).clamp(0.0, 1.0);
    final eased = near * near * (3 - 2 * near);
    return cruiseZoom + (goalZoom - cruiseZoom) * eased;
  }

  /// Metres ahead of the rider the camera aims, so the rider shows at
  /// [riderShare] of the part of a [map] that [padding] leaves in view, the
  /// ground at [metersPerDp] where the camera aims. The map shows its
  /// target in the middle of that part. Seen from straight above, a dp is
  /// [metersPerDp] all over; leaning by [tilt], the road towards the camera
  /// shows foreshortened, the less the nearer it is — a camera [focal] dp
  /// from the screen (the map's height and [fieldOfView]) puts ground `d`
  /// metres behind its target `focal · d · cos(tilt) / (slant − d ·
  /// sin(tilt))` dp below it, `slant` being `metersPerDp · focal` metres to
  /// the target. Solved for `d`. None while the map has no room.
  static double leadMeters({
    required double metersPerDp,
    required Size map,
    required EdgeInsets padding,
    double tilt = LiveMapChaseCamera.tilt,
  }) {
    final visible = map.height - padding.vertical;
    if (visible <= 0 || metersPerDp <= 0) return 0;
    final below = (riderShare - _middle) * visible;
    final focal =
        map.height / 2 / math.tan(fieldOfView * _radiansPerDegree / 2);
    final lean = tilt * _radiansPerDegree;
    return metersPerDp *
        below /
        (math.cos(lean) + below / focal * math.sin(lean));
  }
}
