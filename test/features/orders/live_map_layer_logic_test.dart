// The live map layer's bookkeeping, apart from the native map: when the
// road is worth recutting (LiveMapRoadCutter) and when the camera aims
// (LiveMapFollow).
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_stage.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_camera_action.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_follow.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_road_cutter.dart';

void main() {
  group('LiveMapRoadCutter', () {
    const step = 10.0;
    late LiveMapRoadCutter cutter;

    bool due(CourierStage stage, double drawn, double meters) =>
        cutter.needsRecut(
          stage: stage,
          drawn: drawn,
          meters: meters,
          stepMeters: step,
        );

    setUp(() {
      cutter = LiveMapRoadCutter()
        ..mark(stage: CourierStage.toStore, drawn: 0.5, meters: 100);
    });

    test('the first cut is always due', () {
      expect(
        LiveMapRoadCutter().needsRecut(
          stage: CourierStage.assigning,
          drawn: 0,
          meters: 0,
          stepMeters: step,
        ),
        isTrue,
      );
    });

    test('recuts on a new stage', () {
      expect(due(CourierStage.toStore, 0.5, 100), isFalse);
      expect(due(CourierStage.atStore, 0.5, 100), isTrue);
    });

    test('recuts once the rider moved a step, not before', () {
      expect(due(CourierStage.toStore, 0.5, 100 + step * 0.9), isFalse);
      expect(due(CourierStage.toStore, 0.5, 100 + step), isTrue);
    });

    test('the entrance recuts the planned road as it draws in', () {
      expect(due(CourierStage.toStore, 0.6, 100), isTrue);
    });

    test('once on the way, the entrance never recuts the road', () {
      double drawnAt(double entrance) => LiveMapRoadCutter.drawnAt(
        stage: CourierStage.onTheWay,
        entrance: entrance,
      );
      cutter.mark(
        stage: CourierStage.onTheWay,
        drawn: drawnAt(0.2),
        meters: 500,
      );

      expect(drawnAt(0.2), LiveMapRoadCutter.fullyDrawn);
      expect(due(CourierStage.onTheWay, drawnAt(0.8), 500), isFalse);
      expect(
        LiveMapRoadCutter.drawnAt(stage: CourierStage.toStore, entrance: 0.3),
        0.3,
      );
    });

    test('a reset makes the next cut due', () {
      cutter.reset();

      expect(due(CourierStage.toStore, 0.5, 100), isTrue);
    });
  });

  group('LiveMapFollow', () {
    late LiveMapFollow follow;

    bool aim(
      double left, {
      CourierStage stage = CourierStage.onTheWay,
      bool always = false,
      bool introStarted = true,
    }) => follow.shouldAim(
      stage: stage,
      left: left,
      always: always,
      introStarted: introStarted,
    );

    setUp(() => follow = LiveMapFollow());

    test('no aim is spent before the entrance', () {
      expect(aim(1000, introStarted: false), isFalse);
      expect(aim(1000), isTrue);
    });

    test('within a stage, holds still until the road left clearly shrinks', () {
      expect(aim(1000), isTrue);
      expect(aim(900), isFalse);
      expect(aim(700), isTrue);
    });

    test('a new stage or a recentre always aims', () {
      expect(aim(1000), isTrue);
      expect(aim(990, stage: CourierStage.nearby), isTrue);
      expect(aim(980, stage: CourierStage.nearby, always: true), isTrue);
    });

    test('a reset aims again on the next fix', () {
      expect(aim(1000), isTrue);
      follow.reset();

      expect(aim(990), isTrue);
    });

    test('never while the customer holds the camera', () {
      follow.stop();

      expect(follow.following, isFalse);
      expect(aim(1000, always: true), isFalse);

      follow.resume();
      expect(follow.following, isTrue);
      expect(aim(1000), isTrue);
    });

    group('riding along', () {
      bool chases(CourierStage stage, {bool motion = true}) =>
          follow.chases(stage: stage, motion: motion);
      LiveMapCameraAction? action(CourierStage stage, {bool motion = true}) =>
          follow.action(stage: stage, motion: motion);

      test('while the rider is on the road; framed while the ride stands', () {
        expect(chases(CourierStage.toStore), isTrue);
        expect(chases(CourierStage.onTheWay), isTrue);
        expect(chases(CourierStage.nearby), isTrue);
        expect(chases(CourierStage.assigning), isFalse);
        expect(chases(CourierStage.atStore), isFalse);
        expect(chases(CourierStage.arrived), isFalse);
      });

      test('the button offers the road ahead, none while framing', () {
        expect(action(CourierStage.onTheWay), LiveMapCameraAction.overview);
        expect(action(CourierStage.atStore), isNull);
        expect(action(CourierStage.arrived), isNull);
      });

      test('the road ahead, asked for, holds until riding along again', () {
        follow.showOverview();

        expect(follow.overview, isTrue);
        expect(follow.following, isTrue);
        expect(chases(CourierStage.onTheWay), isFalse);
        expect(action(CourierStage.onTheWay), LiveMapCameraAction.follow);
        // Framing anyway while the ride stands: nothing to offer.
        expect(action(CourierStage.atStore), isNull);

        follow.resume();
        expect(follow.overview, isFalse);
        expect(chases(CourierStage.onTheWay), isTrue);
      });

      test('a drag hands the camera over; the button takes it back', () {
        follow.stop();

        expect(chases(CourierStage.onTheWay), isFalse);
        expect(action(CourierStage.onTheWay), LiveMapCameraAction.follow);
        expect(action(CourierStage.atStore), LiveMapCameraAction.follow);

        follow.resume();
        expect(chases(CourierStage.onTheWay), isTrue);
      });

      test('never with motion reduced: framing, as before', () {
        expect(chases(CourierStage.onTheWay, motion: false), isFalse);
        expect(action(CourierStage.onTheWay, motion: false), isNull);

        follow.stop();
        expect(
          action(CourierStage.onTheWay, motion: false),
          LiveMapCameraAction.follow,
        );
        follow
          ..resume()
          ..showOverview();
        expect(action(CourierStage.onTheWay, motion: false), isNull);
      });
    });
  });
}
