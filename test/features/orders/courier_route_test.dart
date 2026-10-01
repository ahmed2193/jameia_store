import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_route.dart';

import 'courier_test_fakes.dart';

void main() {
  const tolerance = 0.5; // metres

  double metersBetween(GeoPointEntity a, GeoPointEntity b) {
    final from = testFrame.toMeters(a);
    return from.distanceTo(testFrame.toMeters(b));
  }

  group('CourierRoute', () {
    test('measures its road corner to corner', () {
      expect(lRoute().lengthMeters, closeTo(700, tolerance));
    });

    test('finds the point after some metres, on either leg', () {
      final route = lRoute();

      expect(metersBetween(route.pointAt(200), at(0, 200)), lessThan(1));
      expect(metersBetween(route.pointAt(550), at(150, 400)), lessThan(1));
      // Off the road's ends: its ends.
      expect(route.pointAt(-50), route.start);
      expect(metersBetween(route.pointAt(9999), route.end), lessThan(1));
    });

    test('points the heading along the road (north, then east)', () {
      final route = lRoute();

      expect(route.headingAt(100), closeTo(0, 0.5));
      expect(route.headingAt(600), closeTo(90, 0.5));
    });

    test('turns the heading through a corner, not at it', () {
      final route = lRoute();

      // At the corner: half way between north and east.
      expect(route.headingAround(400), closeTo(45, 0.5));
      // On a straight stretch and at the ends: the road's own heading.
      expect(route.headingAround(100), closeTo(route.headingAt(100), 0.01));
      expect(route.headingAround(600), closeTo(route.headingAt(600), 0.01));
      expect(route.headingAround(0), closeTo(route.headingAt(0), 0.01));
      expect(route.headingAround(700), closeTo(route.headingAt(700), 0.01));
      // Just past the corner it has not finished turning yet.
      expect(route.headingAround(403), inExclusiveRange(45, 90));
      // A road of no length: the plain heading.
      expect(CourierRoute([at(0, 0), at(0, 0)]).headingAround(0), 0);
    });

    test('turns through a sharp corner at an even pace', () {
      // 100 m north, then a 150° turn back towards the south-east.
      const turn = 150.0;
      final back = turn * math.pi / 180;
      final route = CourierRoute([
        at(0, 0),
        at(0, 100),
        at(100 * math.sin(back), 100 + 100 * math.cos(back)),
      ]);
      const step = 0.5;
      // Never more than its share of the turn per metre of the window —
      // the line across the window would swing most of the way round where
      // its two sides nearly cancel.
      const most = turn / CourierRoute.turnSpanMeters * step + 1e-6;
      var last = route.headingAround(90);
      for (var meters = 90 + step; meters <= 110; meters += step) {
        final heading = route.headingAround(meters);
        expect(heading - last, inInclusiveRange(0, most), reason: '$meters m');
        last = heading;
      }
      expect(route.headingAround(100), closeTo(turn / 2, 1e-6));
      expect(last, closeTo(turn, 1e-6));
    });

    test('draws the road with only the corners a line needs', () {
      // A run north with points every 50 m (one 0.1 m off the line), a
      // corner, then east with a bend 1 m off the line half way.
      final route = CourierRoute([
        at(0, 0),
        at(0, 50),
        at(0.1, 100),
        at(0, 150),
        at(0, 200),
        at(125, 201),
        at(250, 200),
      ]);

      expect(route.drawPoints, [
        route.points[0],
        route.points[4], // the corner
        route.points[5], // 1 m off the line
        route.points[6],
      ]);
      // The ride itself still runs on every point, the whole length.
      expect(route.points, hasLength(7));
      expect(route.lengthMeters, closeTo(450, 0.1));

      final drawn = route.drawSlice(30, 260);
      expect(drawn, hasLength(3));
      expect(drawn.first, route.pointAt(30));
      expect(drawn[1], route.points[4]);
      expect(drawn.last, route.pointAt(260));
      // The same ends as the full slice, fewer corners in between.
      final full = route.slice(30, 260);
      expect(full, hasLength(6));
      expect(drawn.first, full.first);
      expect(drawn.last, full.last);
      // An empty stretch is two copies of one point.
      final none = route.drawSlice(300, 100);
      expect(none, hasLength(2));
      expect(none.first, none.last);
    });

    test('keeps every corner of a road that comes back to its start', () {
      final loop = CourierRoute([at(0, 0), at(0, 100), at(100, 100), at(0, 0)]);

      expect(loop.drawPoints, loop.points);
    });

    test('slices the road with the corners in between', () {
      final ahead = lRoute().slice(200, 700);

      expect(ahead, hasLength(3));
      expect(metersBetween(ahead[0], at(0, 200)), lessThan(1));
      expect(metersBetween(ahead[1], at(0, 400)), lessThan(1));
      expect(metersBetween(ahead[2], at(300, 400)), lessThan(1));
      // An empty stretch is two copies of one point.
      final none = lRoute().slice(300, 100);
      expect(none, hasLength(2));
      expect(none.first, none.last);
    });

    test('snaps a position a few metres off onto the road', () {
      final route = lRoute();

      expect(route.project(at(4, 250)), closeTo(250, tolerance));
      expect(route.project(at(120, 396)), closeTo(520, tolerance));
    });

    test('never snaps the rider back behind where they were', () {
      final route = lRoute();

      // GPS noise puts the fix 20 m behind: the rider stays put.
      expect(route.project(at(0, 280), from: 300), 300);
      // A fix far ahead is still found (a gap in the fixes).
      expect(route.project(at(250, 400), from: 300), closeTo(650, tolerance));
    });

    test('keeps the search within a leg where two legs share a street', () {
      // Up one side of a divided road, back down the other, 10 m apart.
      final road = CourierRoute([at(0, 0), at(0, 200), at(10, 200), at(10, 0)]);

      // Nearer the way back, but still riding up: stays on the way up.
      expect(road.project(at(8, 100)), closeTo(310, tolerance));
      expect(road.project(at(8, 100), to: 200), closeTo(100, tolerance));
      expect(road.project(at(0, 300), to: 150), closeTo(150, tolerance));
    });

    test('drops repeated points and survives a road of one point', () {
      final repeated = CourierRoute([at(0, 0), at(0, 0), at(0, 100)]);
      expect(repeated.points, hasLength(2));
      expect(repeated.lengthMeters, closeTo(100, tolerance));

      final spot = CourierRoute([at(0, 0), at(0, 0)]);
      expect(spot.lengthMeters, 0);
      expect(spot.pointAt(10), spot.start);
      expect(spot.headingAt(0), 0);
      expect(spot.project(at(50, 50)), 0);
    });
  });

  group('CourierTrip', () {
    test('rides the approach, then the route, as one path', () {
      final trip = testTrip();

      expect(trip.store, lRoute().start);
      expect(trip.home, lRoute().end);
      expect(trip.deliveryStartMeters, closeTo(200, tolerance));
      expect(trip.path.lengthMeters, closeTo(900, tolerance));
    });
  });
}
