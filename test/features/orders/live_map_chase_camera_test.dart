// The camera riding along with the rider (LiveMapChaseCamera): close in,
// tilted, turned with the road, the rider low in the part of the map left
// in view, closing in near the goal — the run that drives it
// (LiveMapChase) and where a glide lands it (LiveMapGlide.metersAhead).
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/hero_map.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_stage.dart';
import 'package:hero_mart/src/features/orders/domain/entities/geo_metric_frame.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_camera.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_chase.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_chase_camera.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_glide.dart';

import 'courier_test_fakes.dart';

void main() {
  // A 900 dp map, 400 dp of it in view between the top bar and the panel.
  const map = Size(400, 900);
  const padding = EdgeInsets.only(top: 100, bottom: 400);
  const visible = 400.0;
  const radiansPerDegree = math.pi / 180;

  // Rider 200 m south of the store → 400 m north to the corner → 300 m
  // east to the door: the corner at 600 m of the path, the door at 900.
  final trip = testTrip();

  group('LiveMapChaseCamera.zoomFor', () {
    test('cruises on the road, closes in on the goal', () {
      expect(
        LiveMapChaseCamera.zoomFor(LiveMapChaseCamera.closeInMeters),
        LiveMapChaseCamera.cruiseZoom,
      );
      expect(LiveMapChaseCamera.zoomFor(5000), LiveMapChaseCamera.cruiseZoom);
      expect(LiveMapChaseCamera.zoomFor(0), LiveMapChaseCamera.goalZoom);
    });

    test('closes in smoothly, never back out, within the zoom range', () {
      var last = LiveMapChaseCamera.cruiseZoom;
      for (var left = LiveMapChaseCamera.closeInMeters; left >= 0; left -= 5) {
        final zoom = LiveMapChaseCamera.zoomFor(left);
        expect(zoom, greaterThanOrEqualTo(last));
        // No jump between two spots 5 m apart.
        expect(zoom - last, lessThan(0.05));
        last = zoom;
      }
      expect(LiveMapChaseCamera.goalZoom, LiveMapCamera.maxZoom);
    });
  });

  group('LiveMapChaseCamera.bearingAt', () {
    test('turns the map with the road: north, then east', () {
      expect(LiveMapChaseCamera.bearingAt(trip.path, 300), closeTo(0, 1e-9));
      expect(LiveMapChaseCamera.bearingAt(trip.path, 800), closeTo(90, 1e-9));
    });

    test('through a corner, a touch calmer than the rider', () {
      const corner = 600.0;
      final camera = LiveMapChaseCamera.bearingAt(trip.path, corner);
      final rider = trip.path.headingAround(corner);

      expect(camera, greaterThan(0));
      expect(camera, lessThan(rider));
      // Both have come round once past the corner.
      expect(
        LiveMapChaseCamera.bearingAt(trip.path, corner + 20),
        closeTo(90, 1e-9),
      );
    });
  });

  group('LiveMapChaseCamera.leadMeters', () {
    const metersPerDp = 1.2;
    final below = (LiveMapChaseCamera.riderShare - 0.5) * visible;

    test('from straight above: the rider a fixed number of dp low', () {
      expect(
        LiveMapChaseCamera.leadMeters(
          metersPerDp: metersPerDp,
          map: map,
          padding: padding,
          tilt: 0,
        ),
        closeTo(below * metersPerDp, 1e-9),
      );
    });

    test('tilted: the rider shows at the same spot on screen', () {
      final lead = LiveMapChaseCamera.leadMeters(
        metersPerDp: metersPerDp,
        map: map,
        padding: padding,
      );
      // Project the ground `lead` metres behind the target through a camera
      // leaning by the tilt, `slant` metres from the target, `focal` dp from
      // the screen: where does it show?
      final focal =
          map.height /
          2 /
          math.tan(LiveMapChaseCamera.fieldOfView * radiansPerDegree / 2);
      final slant = metersPerDp * focal;
      final lean = LiveMapChaseCamera.tilt * radiansPerDegree;
      final toward = slant * math.sin(lean) - lead;
      final height = slant * math.cos(lean);
      // Camera → ground, along the view and the screen's up.
      final along = toward * math.sin(lean) + height * math.cos(lean);
      final up = toward * math.cos(lean) - height * math.sin(lean);
      final shownBelow = -focal * up / along;

      expect(shownBelow, closeTo(below, 1e-6));
      // Leaning foreshortens the road: the camera aims further ahead than
      // from above.
      expect(lead, greaterThan(below * metersPerDp));
    });

    test('scales with the ground a dp covers', () {
      double lead(double metersPerDp) => LiveMapChaseCamera.leadMeters(
        metersPerDp: metersPerDp,
        map: map,
        padding: padding,
      );

      expect(lead(2), closeTo(lead(1) * 2, 1e-9));
    });

    test('none while the map has no room', () {
      expect(
        LiveMapChaseCamera.leadMeters(
          metersPerDp: metersPerDp,
          map: map,
          padding: const EdgeInsets.only(top: 500, bottom: 400),
        ),
        0,
      );
      expect(
        LiveMapChaseCamera.leadMeters(
          metersPerDp: metersPerDp,
          map: Size.zero,
          padding: EdgeInsets.zero,
        ),
        0,
      );
    });
  });

  group('LiveMapChaseCamera.position', () {
    /// Metres east / north of [from] to [to].
    math.Point<double> offset(GeoPointEntity from, CameraPosition camera) =>
        GeoMetricFrame(from).toMeters(
          GeoPointEntity(
            lat: camera.target.latitude,
            lng: camera.target.longitude,
          ),
        );

    test('leans in, turned with the road, the rider low in view', () {
      const meters = 300.0;
      final camera = LiveMapChaseCamera.position(
        trip,
        meters,
        CourierStage.toStore,
        map: map,
        padding: padding,
      );
      final rider = trip.path.pointAt(meters);
      final lead = LiveMapChaseCamera.leadMeters(
        metersPerDp: LiveMapCamera.metersPerDp(camera.zoom, rider.lat),
        map: map,
        padding: padding,
      );
      final ahead = offset(rider, camera);

      expect(camera.tilt, LiveMapChaseCamera.tilt);
      expect(camera.bearing, closeTo(0, 1e-9));
      expect(lead, greaterThan(0));
      // Aimed `lead` metres up the road (north here).
      expect(ahead.x, closeTo(0, 1e-6));
      expect(ahead.y, closeTo(lead, 1e-6));
    });

    test('aims up the road the way the map is turned', () {
      const meters = 700.0;
      final camera = LiveMapChaseCamera.position(
        trip,
        meters,
        CourierStage.onTheWay,
        map: map,
        padding: padding,
      );
      final ahead = offset(trip.path.pointAt(meters), camera);

      expect(camera.bearing, closeTo(90, 1e-9));
      expect(ahead.x, greaterThan(0));
      expect(ahead.y, closeTo(0, 1e-6));
    });

    test('closes in on the goal: the store, then the door', () {
      CameraPosition at(double meters, CourierStage stage) =>
          LiveMapChaseCamera.position(
            trip,
            meters,
            stage,
            map: map,
            padding: padding,
          );

      // 600 m of road to the door; 20 m to the store.
      expect(
        at(300, CourierStage.onTheWay).zoom,
        LiveMapChaseCamera.cruiseZoom,
      );
      expect(
        at(180, CourierStage.toStore).zoom,
        greaterThan(LiveMapChaseCamera.cruiseZoom),
      );
      expect(
        at(trip.path.lengthMeters, CourierStage.nearby).zoom,
        LiveMapChaseCamera.goalZoom,
      );
    });

    test('moves as little as the rider does', () {
      final before = LiveMapChaseCamera.position(
        trip,
        300,
        CourierStage.onTheWay,
        map: map,
        padding: padding,
      );
      final after = LiveMapChaseCamera.position(
        trip,
        300.1,
        CourierStage.onTheWay,
        map: map,
        padding: padding,
      );
      final moved =
          GeoMetricFrame(
            GeoPointEntity(
              lat: before.target.latitude,
              lng: before.target.longitude,
            ),
          ).toMeters(
            GeoPointEntity(
              lat: after.target.latitude,
              lng: after.target.longitude,
            ),
          );

      // 0.1 m up the road (the ground a dp covers shifts with the latitude:
      // well under a millimetre).
      expect(
        moved.distanceTo(const math.Point<double>(0, 0.1)),
        lessThan(1e-4),
      );
      expect(after.bearing, before.bearing);
      expect(after.zoom, before.zoom);
    });
  });

  group('LiveMapChase', () {
    testWidgets('glides in first, then keeps to the rider', (tester) async {
      final chase = LiveMapChase();
      var lives = 0;
      chase.flyIn(() => lives++);

      expect(chase.active, isTrue);
      expect(chase.live, isFalse);
      // Nothing moves the camera while the glide runs.
      expect(chase.shouldTrack(10, force: true), isFalse);

      await tester.pump(
        AppMotion.cameraGlide - const Duration(milliseconds: 1),
      );
      expect(lives, 0);
      await tester.pump(const Duration(milliseconds: 1));
      expect(lives, 1);
      expect(chase.live, isTrue);
      chase.end();
    });

    testWidgets('moves the camera only for a rider who moved', (tester) async {
      final chase = LiveMapChase()..flyIn(() {});
      await tester.pump(AppMotion.cameraGlide);

      expect(chase.shouldTrack(10), isTrue);
      expect(chase.shouldTrack(10), isFalse);
      expect(chase.shouldTrack(10.5), isTrue);
      // The room around the map changed: aim again, moved or not.
      expect(chase.shouldTrack(10.5, force: true), isTrue);
      chase.end();
    });

    testWidgets('an end stops the glide in and the riding along', (
      tester,
    ) async {
      final chase = LiveMapChase();
      var lives = 0;
      chase
        ..flyIn(() => lives++)
        ..end();

      await tester.pump(AppMotion.cameraGlide * 2);
      expect(lives, 0);
      expect(chase.active, isFalse);

      chase.flyIn(() => lives++);
      await tester.pump(AppMotion.cameraGlide);
      chase.end();
      expect(chase.live, isFalse);
      expect(chase.shouldTrack(10), isFalse);
    });

    testWidgets('a new glide in replaces the one running', (tester) async {
      final chase = LiveMapChase();
      final lives = <String>[];
      chase.flyIn(() => lives.add('first'));
      await tester.pump(AppMotion.cameraGlide ~/ 2);
      chase.flyIn(() => lives.add('second'));

      await tester.pump(AppMotion.cameraGlide);
      expect(lives, ['second']);
      chase.end();
    });
  });

  group('LiveMapGlide.metersAhead', () {
    const length = Duration(seconds: 2);

    double ahead(double done, Duration ahead) => LiveMapGlide.metersAhead(
      from: 100,
      to: 120,
      done: done,
      length: length,
      ahead: ahead,
    );

    test('on along the glide at its pace', () {
      expect(ahead(0.5, const Duration(milliseconds: 500)), closeTo(115, 1e-9));
      expect(ahead(0, Duration.zero), 100);
    });

    test('stops where the glide ends', () {
      expect(ahead(0.9, const Duration(seconds: 1)), 120);
      expect(
        LiveMapGlide.metersAhead(
          from: 100,
          to: 120,
          done: 0,
          length: Duration.zero,
          ahead: const Duration(seconds: 1),
        ),
        120,
      );
    });
  });
}
