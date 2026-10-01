import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/core/widgets/hero_map.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_stage.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_camera.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_marker_icons.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_overlays.dart';

import 'courier_test_fakes.dart';

void main() {
  final trip = testTrip();
  final overlays = LiveMapOverlays(
    trip: trip,
    icons: LiveMapMarkerIcons.fallback,
  );

  Map<String, Polyline> linesAt(double meters, CourierStage stage) => {
    for (final line in overlays.polylines(
      lineMeters: meters,
      stage: stage,
      drawn: 1,
    ))
      line.polylineId.value: line,
  };

  group('LiveMapOverlays', () {
    test('no road is driven before a rider is found', () {
      expect(linesAt(0, CourierStage.assigning), isNot(contains('travelled')));
    });

    test('the road already driven is greyed out behind the rider', () {
      final toStore = linesAt(100, CourierStage.toStore);
      final onTheWay = linesAt(
        trip.deliveryStartMeters + 100,
        CourierStage.onTheWay,
      );

      expect(toStore['travelled']?.color, AppColors.disabledText);
      expect(toStore, contains('approach'));
      expect(onTheWay['travelled']?.color, AppColors.disabledText);
      expect(onTheWay['road']?.color, AppColors.primary);
      // Grey on the same white casing, laid under the road ahead.
      expect(onTheWay['travelled_casing']?.color, AppColors.white);
      expect(onTheWay['travelled']!.width, onTheWay['road']!.width);
      expect(
        onTheWay['travelled_casing']!.zIndex,
        lessThan(onTheWay['casing']!.zIndex),
      );
      expect(onTheWay['travelled']!.zIndex, lessThan(onTheWay['road']!.zIndex));
      // Before the store the grey line ends under the rider; once on the
      // way it is the whole ride, and the green starts under the rider.
      expect(
        toStore['travelled']!.points.last,
        LiveMapCamera.latLng(trip.path.pointAt(100)),
      );
      expect(
        onTheWay['travelled']!.points.first,
        LiveMapCamera.latLng(trip.path.start),
      );
      expect(
        onTheWay['travelled']!.points.last,
        LiveMapCamera.latLng(trip.path.end),
      );
      expect(
        onTheWay['road']!.points.first,
        LiveMapCamera.latLng(trip.path.pointAt(trip.deliveryStartMeters + 100)),
      );
    });

    test('on the way, the road driven is one fixed pair: never sent again', () {
      final first = linesAt(
        trip.deliveryStartMeters + 50,
        CourierStage.onTheWay,
      );
      final later = linesAt(
        trip.deliveryStartMeters + 250,
        CourierStage.nearby,
      );

      expect(identical(first['travelled'], later['travelled']), isTrue);
      expect(
        identical(first['travelled_casing'], later['travelled_casing']),
        isTrue,
      );
      // The road ahead is still cut at the rider.
      expect(first['road'], isNot(later['road']));
    });

    test('at the door, the whole ride is driven', () {
      final arrived = linesAt(trip.path.lengthMeters, CourierStage.arrived);

      expect(arrived.keys, unorderedEquals(['travelled', 'travelled_casing']));
      final onTheWay = linesAt(
        trip.deliveryStartMeters + 100,
        CourierStage.onTheWay,
      );
      expect(identical(arrived['travelled'], onTheWay['travelled']), isTrue);
      expect(
        identical(arrived['travelled_casing'], onTheWay['travelled_casing']),
        isTrue,
      );
      expect(
        arrived['travelled']!.points.last,
        overlays
            .polylines(
              lineMeters: trip.path.lengthMeters,
              stage: CourierStage.onTheWay,
              drawn: 1,
            )
            .firstWhere((line) => line.polylineId.value == 'travelled')
            .points
            .last,
      );
    });

    test('the store pin sits on the tip of its named pin', () {
      final store = overlays
          .markers(riderMeters: 0, stage: CourierStage.assigning, riderAlpha: 0)
          .firstWhere((marker) => marker.markerId.value == 'store');

      expect(store.anchor, LiveMapMarkerIcons.fallback.storeAnchor);
    });

    test('the rider turns through a corner, not at it', () {
      Marker riderAt(double meters) => overlays
          .markers(
            riderMeters: meters,
            stage: CourierStage.onTheWay,
            riderAlpha: 1,
          )
          .firstWhere((marker) => marker.markerId.value == 'rider');
      // The L route turns from north to east 400 m past the store.
      final corner = trip.deliveryStartMeters + 400;

      expect(riderAt(corner).rotation, closeTo(45, 1));
      // Straight road: the road's own heading (north), across 0° / 360°.
      final straight = riderAt(corner - 100).rotation;
      expect(((straight + 180) % 360 - 180).abs(), lessThan(1e-6));
    });
  });

  group('LiveMapOverlays.rings', () {
    const laps = 4;
    final center = trip.home;

    Map<String, Circle> ringsAt(double lapsDone) => {
      for (final ring in overlays.rings(
        center,
        AppColors.proAmber,
        lapsDone: lapsDone,
        laps: laps,
      ))
        ring.circleId.value: ring,
    };

    test('the first ring is born alone, small and strong', () {
      final born = ringsAt(0);

      expect(born.keys, ['ring0']);
      expect(born['ring0']!.radius, lessThan(ringsAt(0.5)['ring0']!.radius));
    });

    test('the second ring is born half a lap later, at the same size', () {
      final half = ringsAt(0.5);

      expect(half.keys, unorderedEquals(['ring0', 'ring1']));
      expect(half['ring1']!.radius, ringsAt(0)['ring0']!.radius);
      expect(half['ring1']!.fillColor, ringsAt(0)['ring0']!.fillColor);
    });

    test(
      'the last lap only fades the rings out; none once all laps are done',
      () {
        // The first ring ends its last grown lap almost clear.
        final fading = ringsAt(laps - 1 - 0.01);
        expect(fading['ring0']!.fillColor.a, lessThan(0.01));
        expect(ringsAt(laps - 1).keys, ['ring1']);
        expect(ringsAt(laps.toDouble()), isEmpty);
      },
    );
  });
}
