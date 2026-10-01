import 'dart:async';
import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_fix.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_route.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_trip.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_trip_request.dart';
import 'package:hero_mart/src/features/orders/domain/entities/geo_metric_frame.dart';
import 'package:hero_mart/src/features/orders/domain/repositories/courier_tracking_repository.dart';

/// Salmiya — where the test rides happen.
const GeoPointEntity testOrigin = GeoPointEntity(lat: 29.33, lng: 48.07);

const GeoMetricFrame testFrame = GeoMetricFrame(testOrigin);

/// The point [east] / [north] metres from [testOrigin].
GeoPointEntity at(double east, double north) =>
    testFrame.toPoint(math.Point<double>(east, north));

/// 400 m north, then 300 m east: 700 m, one corner at 400.
CourierRoute lRoute() => CourierRoute([at(0, 0), at(0, 400), at(300, 400)]);

/// Rider 200 m south of the store → store → door (the L route).
CourierTrip testTrip({String riderName = 'Ali', String riderPhone = ''}) =>
    CourierTrip(
      orderId: 'o1',
      approach: CourierRoute([at(0, -200), at(0, 0)]),
      route: lRoute(),
      riderName: riderName,
      riderPhone: riderPhone,
    );

final DateTime fixTime = DateTime.utc(2026, 9, 30, 10);

CourierFix fixAt(
  GeoPointEntity position, {
  int second = 0,
  CourierFixState state = CourierFixState.onTheWay,
  int? etaSeconds,
}) => CourierFix(
  position: position,
  at: fixTime.add(Duration(seconds: second)),
  state: state,
  etaSeconds: etaSeconds,
);

/// A repository whose ride and fixes the test controls.
class FakeCourierTrackingRepository implements CourierTrackingRepository {
  FakeCourierTrackingRepository({this.trip});

  CourierTrip? trip;
  Failure? tripFailure;
  final List<CourierTripRequest> requests = <CourierTripRequest>[];

  /// One controller per `watchCourier` call (the latest last).
  final List<StreamController<CourierFix>> feeds =
      <StreamController<CourierFix>>[];

  StreamController<CourierFix> get feed => feeds.last;

  @override
  Future<Either<Failure, CourierTrip>> getTrip(
    CourierTripRequest request,
  ) async {
    requests.add(request);
    final failure = tripFailure;
    if (failure != null) return Left(failure);
    return Right(trip ?? testTrip());
  }

  @override
  Stream<CourierFix> watchCourier(String orderId) {
    final controller = StreamController<CourierFix>();
    feeds.add(controller);
    return controller.stream;
  }
}
