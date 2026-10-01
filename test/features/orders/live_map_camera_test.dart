import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_stage.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_camera.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_frame_gate.dart';

import 'courier_test_fakes.dart';

void main() {
  group('LiveMapCamera.metersPerDp', () {
    test('the world is 256 dp wide at zoom 0 on the equator', () {
      expect(LiveMapCamera.metersPerDp(0, 0), closeTo(156543.03392, 1e-6));
    });

    test('halves with every zoom level', () {
      expect(
        LiveMapCamera.metersPerDp(17, 0),
        closeTo(LiveMapCamera.metersPerDp(16, 0) / 2, 1e-9),
      );
    });

    test('shrinks with the latitude', () {
      expect(
        LiveMapCamera.metersPerDp(10, 60),
        closeTo(LiveMapCamera.metersPerDp(10, 0) / 2, 1e-9),
      );
    });
  });

  group('LiveMapCamera.follow', () {
    final trip = testTrip();

    List<Object?> follow(double riderMeters, CourierStage stage) =>
        LiveMapCamera.follow(trip, riderMeters, stage).toJson()
            as List<Object?>;

    test('a rider being found: the whole ride', () {
      expect(
        follow(0, CourierStage.assigning),
        LiveMapCamera.overview(trip).toJson(),
      );
    });

    test('far from the store: the rider and the store framed', () {
      expect(follow(0, CourierStage.toStore).first, 'newLatLngBounds');
    });

    /// A close-up of [point]: from straight above, north up, whatever a
    /// camera riding along left behind.
    Matcher closeUpOf(GeoPointEntity point) => equals(<Object?>[
      'newCameraPosition',
      <String, Object?>{
        'bearing': 0.0,
        'target': LiveMapCamera.latLng(point).toJson(),
        'tilt': 0.0,
        'zoom': LiveMapCamera.spotZoom,
      },
    ]);

    test('almost at the store: the store, close up', () {
      expect(
        follow(trip.deliveryStartMeters - 10, CourierStage.toStore),
        closeUpOf(trip.store),
      );
    });

    test('on the way: the rider and the door framed', () {
      expect(
        follow(trip.deliveryStartMeters + 100, CourierStage.onTheWay).first,
        'newLatLngBounds',
      );
    });

    test('at the door: the door, close up', () {
      expect(
        follow(trip.path.lengthMeters, CourierStage.arrived),
        closeUpOf(trip.home),
      );
    });
  });

  group('LiveMapCamera frame padding', () {
    final trip = testTrip();

    test('a plain pin keeps the frame padding', () {
      expect(
        LiveMapCamera.framePaddingFor(
          const Size(40, 48),
          const Offset(0.5, 0.5),
        ),
        LiveMapCamera.framePadding,
      );
    });

    test('a named pin keeps room for its bubble, sideways and above', () {
      // 160 dp wide: 80 dp each side of its tip, plus a clearance.
      final wide = LiveMapCamera.framePaddingFor(
        const Size(160, 90),
        const Offset(0.5, 0.9),
      );
      // 200 dp tall, tip at the foot: 190 dp above its tip.
      final tall = LiveMapCamera.framePaddingFor(
        const Size(60, 200),
        const Offset(0.5, 0.95),
      );

      expect(wide, greaterThan(80));
      expect(tall, greaterThan(190));
    });

    test('the padding reaches the framed bounds', () {
      const padding = 90.0;
      final overview =
          LiveMapCamera.overview(trip, padding: padding).toJson()
              as List<Object?>;
      final onTheWay =
          LiveMapCamera.follow(
                trip,
                trip.deliveryStartMeters + 100,
                CourierStage.onTheWay,
                padding: padding,
              ).toJson()
              as List<Object?>;

      expect(overview.first, 'newLatLngBounds');
      expect(overview.last, padding);
      expect(onTheWay.first, 'newLatLngBounds');
      expect(onTheWay.last, padding);
      expect(
        (LiveMapCamera.overview(trip).toJson() as List<Object?>).last,
        LiveMapCamera.framePadding,
      );
    });
  });

  group('LiveMapCamera reframing', () {
    final trip = testTrip();

    test('the road left: to the store, then to the door; none while the '
        'ride stands', () {
      expect(
        LiveMapCamera.leftMeters(trip, 50, CourierStage.toStore),
        trip.deliveryStartMeters - 50,
      );
      expect(
        LiveMapCamera.leftMeters(
          trip,
          trip.deliveryStartMeters + 100,
          CourierStage.onTheWay,
        ),
        closeTo(trip.path.lengthMeters - trip.deliveryStartMeters - 100, 1e-9),
      );
      expect(LiveMapCamera.leftMeters(trip, 0, CourierStage.atStore), 0);
      expect(
        LiveMapCamera.leftMeters(
          trip,
          trip.path.lengthMeters + 5,
          CourierStage.nearby,
        ),
        0,
      );
    });

    test('holds still until the road left clearly shrinks', () {
      expect(LiveMapCamera.shouldReframe(aimedLeft: 1000, left: 900), isFalse);
      expect(LiveMapCamera.shouldReframe(aimedLeft: 1000, left: 700), isTrue);
    });

    test('closes in once within a spot, then never again', () {
      expect(LiveMapCamera.shouldReframe(aimedLeft: 100, left: 79), isTrue);
      expect(LiveMapCamera.shouldReframe(aimedLeft: 79, left: 10), isFalse);
      expect(LiveMapCamera.shouldReframe(aimedLeft: 0, left: 0), isFalse);
    });

    test('on the way, the frame holds every bend of the road left', () {
      final rider = trip.deliveryStartMeters + 50;
      final bounds =
          (LiveMapCamera.follow(trip, rider, CourierStage.onTheWay).toJson()
                  as List<Object?>)[1]!
              as List<Object?>;
      final south = (bounds[0]! as List<Object?>)[0]! as double;
      final north = (bounds[1]! as List<Object?>)[0]! as double;
      for (final point in trip.path.slice(rider, trip.path.lengthMeters)) {
        expect(point.lat, inInclusiveRange(south, north));
      }
    });
  });

  group('LiveMapFrameGate', () {
    const zoom = 16.0;
    const lat = 29.37;
    final halfDp = LiveMapCamera.metersPerDp(zoom, lat) / 2;

    bool moved(double meters, double heading, {double shownHeading = 0}) =>
        LiveMapFrameGate.riderMoved(
          shownMeters: 100,
          shownHeading: shownHeading,
          meters: 100 + meters,
          heading: heading,
          zoom: zoom,
          latitude: lat,
        );

    test('a frame once the rider moved half a dp on screen, or turned', () {
      expect(moved(halfDp * 0.9, 1), isFalse);
      expect(moved(halfDp * 1.1, 0), isTrue);
      expect(moved(0, 3), isTrue);
      // Across north: 359° → 1° is a 2° turn, not 358°.
      expect(moved(0, 1, shownHeading: 359), isTrue);
      expect(moved(0, 0.5, shownHeading: 359), isFalse);
    });

    test('riding along, the map moves in finer steps', () {
      bool chased(double meters) => LiveMapFrameGate.riderMoved(
        shownMeters: 100,
        shownHeading: 0,
        meters: 100 + meters,
        heading: 0,
        zoom: zoom,
        latitude: lat,
        stepDp: LiveMapFrameGate.chaseStepDp,
      );
      final step = LiveMapFrameGate.chaseStepDp * halfDp * 2;

      expect(
        LiveMapFrameGate.chaseStepDp,
        lessThan(LiveMapFrameGate.minStepDp),
      );
      expect(chased(step * 0.9), isFalse);
      expect(chased(step * 1.1), isTrue);
      expect(moved(step * 1.1, 0), isFalse);
    });

    test('the road is recut per 8 dp on screen, at least every 6 m', () {
      expect(
        LiveMapFrameGate.lineStepMeters(zoom, lat),
        closeTo(8 * LiveMapCamera.metersPerDp(zoom, lat), 1e-9),
      );
      expect(LiveMapFrameGate.lineStepMeters(21, lat), 6);
    });

    test('never two frames within the frame gap', () {
      const last = Duration(milliseconds: 1000);

      expect(
        LiveMapFrameGate.tooSoon(last, last + const Duration(milliseconds: 20)),
        isTrue,
      );
      expect(
        LiveMapFrameGate.tooSoon(last, last + LiveMapFrameGate.frameGap),
        isFalse,
      );
    });
  });
}
