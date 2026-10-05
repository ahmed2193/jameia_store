// The map picker: the pin's states as the map moves and settles, the read
// of the address under it (late answers dropped), the delivery area, "find
// me" and the camera moves it asks of the map.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/address/domain/entities/device_location.dart';
import 'package:hero_mart/src/features/address/domain/entities/map_destination.dart';
import 'package:hero_mart/src/features/address/domain/entities/pinned_place.dart';
import 'package:hero_mart/src/features/address/domain/entities/place_spot.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_picker_cubit.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_picker_state.dart';

import 'address_picker_test_fakes.dart';

void main() {
  late PickerFakes fakes;

  /// Past the settle pause, with the read answered.
  Future<void> settle() =>
      Future<void>.delayed(AddressPickerCubit.settleDelay * 2);

  setUp(() {
    fakes = PickerFakes()
      ..resolvePin.answer = (point) =>
          PinnedPlace(location: point, area: 'Salmiya', street: 'Street 1');
  });

  group('opening', () {
    test('a new address opens close up on the last known position, then '
        'glides to a fresh fix', () async {
      fakes.lastKnown.result = const Right(DeviceLocation.found(jahra));
      fakes.locateDevice.result = const Right(DeviceLocation.found(salmiya));
      final cubit = fakes.cubit();
      addTearDown(cubit.close);
      // No map until it knows where to open; nothing to confirm.
      expect(cubit.state.opened, isFalse);
      expect(cubit.state.canConfirm, isFalse);

      await cubit.start(languageCode: 'en', findMe: true);

      expect(cubit.state.opened, isTrue);
      expect(cubit.state.target, jahra);
      expect(cubit.state.openingZoom, AddressPickerState.doorZoom);
      expect(cubit.state.showsMyLocation, isTrue);
      expect(cubit.state.camera?.target, salmiya);
      expect(cubit.state.camera?.zoom, AddressPickerState.doorZoom);
      expect(cubit.state.camera?.glide, isTrue);
      expect(fakes.locateDevice.calls.single.ask, isTrue);
      expect(cubit.state.notice, isNull);
    });

    test('with no position known yet the map waits, then opens close up on '
        'the fresh fix — no flight from the city', () async {
      final gate = Completer<void>();
      fakes.locateDevice
        ..gate = gate
        ..result = const Right(DeviceLocation.found(salmiya));
      final cubit = fakes.cubit();
      addTearDown(cubit.close);
      final starting = cubit.start(languageCode: 'en', findMe: true);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.opened, isFalse);

      gate.complete();
      await starting;

      expect(cubit.state.opened, isTrue);
      expect(cubit.state.target, salmiya);
      expect(cubit.state.openingZoom, AddressPickerState.doorZoom);
      expect(cubit.state.camera, isNull);
    });

    test('when the device cannot tell, the map opens on Kuwait City', () async {
      fakes.locateDevice.result = const Right(
        DeviceLocation.missing(DeviceLocationStatus.serviceOff),
      );
      final cubit = fakes.cubit();
      addTearDown(cubit.close);

      await cubit.start(languageCode: 'en', findMe: true);

      expect(cubit.state.opened, isTrue);
      expect(cubit.state.target, GeoPointEntity.kuwaitCity);
      expect(cubit.state.openingZoom, AddressPickerState.cityZoom);
      expect(cubit.state.camera, isNull);
    });

    test('a place picked in the search before anything was found opens the '
        'map there; the fix that comes later leaves it', () async {
      final gate = Completer<void>();
      fakes.locateDevice
        ..gate = gate
        ..result = const Right(DeviceLocation.found(salmiya));
      final cubit = fakes.cubit();
      addTearDown(cubit.close);
      final starting = cubit.start(languageCode: 'en', findMe: true);
      await Future<void>.delayed(Duration.zero);

      cubit.goTo(
        const PlaceDestination(PlaceSpot(location: jahra, title: 'Jahra')),
      );
      expect(cubit.state.opened, isTrue);
      expect(cubit.state.target, jahra);
      expect(cubit.state.openingZoom, AddressPickerState.streetZoom);
      gate.complete();
      await starting;

      expect(cubit.state.target, jahra);
      expect(cubit.state.camera, isNull);
    });

    test(
      'a fresh fix never pulls the map from where the customer took it',
      () async {
        final gate = Completer<void>();
        fakes.locateDevice
          ..gate = gate
          ..result = const Right(DeviceLocation.found(salmiya));
        final cubit = fakes.cubit();
        addTearDown(cubit.close);
        final starting = cubit.start(languageCode: 'en', findMe: true);
        await Future<void>.delayed(Duration.zero);

        cubit
          ..cameraMoveStarted() // the customer drags
          ..cameraIdle(jahra);
        final movesBefore = cubit.state.camera;
        gate.complete();
        await starting;

        expect(cubit.state.camera, movesBefore);
      },
    );

    test('quietly says nothing when the device cannot tell', () async {
      fakes.locateDevice.result = const Right(
        DeviceLocation.missing(DeviceLocationStatus.denied),
      );
      final cubit = fakes.cubit();
      addTearDown(cubit.close);
      final notices = <LocationNotice?>[];
      final sub = cubit.stream.listen((state) => notices.add(state.notice));
      addTearDown(sub.cancel);

      await cubit.start(languageCode: 'en', findMe: true);
      await Future<void>.delayed(Duration.zero);

      expect(notices.whereType<LocationNotice>(), isEmpty);
    });

    test('an address being edited opens on its pin, read already: settling '
        'there reads nothing', () async {
      const saved = PinnedPlace(location: jahra, area: 'Jahra', block: '4');
      final cubit = fakes.cubit(pinned: saved);
      addTearDown(cubit.close);
      expect(cubit.state.pin, PinStatus.ready);
      expect(cubit.state.place, saved);
      expect(cubit.state.opened, isTrue);
      expect(cubit.state.openingZoom, AddressPickerState.doorZoom);

      await cubit.start(languageCode: 'en', findMe: false);
      cubit.cameraIdle(jahra);
      await settle();

      expect(fakes.resolvePin.calls, isEmpty);
      expect(fakes.locateDevice.calls, isEmpty);
      expect(cubit.state.place, saved);
    });
  });

  group('the pin', () {
    test(
      'lifts while the map moves, reads the address once it settles',
      () async {
        final cubit = fakes.cubit();
        addTearDown(cubit.close);
        await cubit.start(languageCode: 'ar', findMe: false);

        cubit.cameraMoveStarted();
        expect(cubit.state.pin, PinStatus.moving);
        expect(cubit.state.canConfirm, isFalse);

        cubit.cameraIdle(salmiya);
        expect(cubit.state.pin, PinStatus.resolving);
        expect(cubit.state.target, salmiya);
        expect(fakes.resolvePin.calls, isEmpty); // waits for the pause
        await settle();

        expect(cubit.state.pin, PinStatus.ready);
        expect(cubit.state.place?.area, 'Salmiya');
        expect(fakes.resolvePin.calls.single.point, salmiya);
        expect(fakes.resolvePin.calls.single.languageCode, 'ar');
      },
    );

    test('a quick second drag reads only where the map stopped', () async {
      final cubit = fakes.cubit();
      addTearDown(cubit.close);
      await cubit.start(languageCode: 'en', findMe: false);

      cubit
        ..cameraMoveStarted()
        ..cameraIdle(salmiya)
        ..cameraMoveStarted()
        ..cameraIdle(jahra);
      await settle();

      expect(fakes.resolvePin.calls.single.point, jahra);
      expect(cubit.state.place?.location, jahra);
    });

    test('an answer for a spot the map has left is dropped', () async {
      final gate = Completer<void>();
      fakes.resolvePin.gate = gate;
      final cubit = fakes.cubit();
      addTearDown(cubit.close);
      await cubit.start(languageCode: 'en', findMe: false);

      cubit.cameraIdle(salmiya);
      await settle(); // the read for Salmiya is in flight
      cubit.cameraMoveStarted();
      gate.complete();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.pin, PinStatus.moving);
      expect(cubit.state.place, isNull);
    });

    test(
      'one read at a time: a spot settled meanwhile is read after it',
      () async {
        final gate = Completer<void>();
        fakes.resolvePin.gate = gate;
        final cubit = fakes.cubit();
        addTearDown(cubit.close);
        await cubit.start(languageCode: 'en', findMe: false);

        cubit.cameraIdle(salmiya);
        await settle(); // Salmiya is being read
        cubit
          ..cameraMoveStarted()
          ..cameraIdle(jahra);
        await settle();
        expect(fakes.resolvePin.calls, hasLength(1));

        gate.complete();
        await settle();
        expect(fakes.resolvePin.calls.map((call) => call.point), [
          salmiya,
          jahra,
        ]);
        expect(cubit.state.pin, PinStatus.ready);
        expect(cubit.state.place?.location, jahra);
      },
    );

    test('a nudge of a step keeps the address already read', () async {
      final cubit = fakes.cubit();
      addTearDown(cubit.close);
      await cubit.start(languageCode: 'en', findMe: false);
      cubit.cameraIdle(salmiya);
      await settle();

      const nudged = GeoPointEntity(lat: 29.334015, lng: 48.078);
      cubit
        ..cameraMoveStarted()
        ..cameraIdle(nudged);

      expect(cubit.state.pin, PinStatus.ready);
      expect(cubit.state.place?.location, nudged);
      expect(cubit.state.place?.street, 'Street 1');
      expect(fakes.resolvePin.calls, hasLength(1));
    });

    test(
      'confirm waits for the spot it stands on, past an older read',
      () async {
        final gate = Completer<void>();
        fakes.resolvePin.gate = gate;
        final cubit = fakes.cubit();
        addTearDown(cubit.close);
        await cubit.start(languageCode: 'en', findMe: false);
        cubit.cameraIdle(salmiya);
        await settle(); // Salmiya is being read
        cubit
          ..cameraMoveStarted()
          ..cameraIdle(jahra);

        final confirming = cubit.confirm();
        gate.complete();
        final place = await confirming;

        expect(place?.location, jahra);
        expect(fakes.resolvePin.calls.last.point, jahra);
      },
    );

    test(
      'settled outside the delivery area: no read, nothing to confirm',
      () async {
        final cubit = fakes.cubit();
        addTearDown(cubit.close);
        await cubit.start(languageCode: 'en', findMe: false);

        cubit.cameraIdle(marrakesh);
        await settle();

        expect(cubit.state.pin, PinStatus.outside);
        expect(cubit.state.canConfirm, isFalse);
        expect(fakes.resolvePin.calls, isEmpty);
        expect(await cubit.confirm(), isNull);
      },
    );

    test('a failed read still leaves the bare point to confirm', () async {
      fakes.resolvePin.failure = const NetworkFailure();
      final cubit = fakes.cubit();
      addTearDown(cubit.close);
      await cubit.start(languageCode: 'en', findMe: false);

      cubit.cameraIdle(salmiya);
      await settle();

      expect(cubit.state.pin, PinStatus.ready);
      expect(cubit.state.place, const PinnedPlace.at(salmiya));
    });
  });

  group('confirm', () {
    test('while the address is still being read, it reads it now and '
        'answers with it', () async {
      final cubit = fakes.cubit();
      addTearDown(cubit.close);
      await cubit.start(languageCode: 'en', findMe: false);
      cubit.cameraIdle(salmiya);

      final place = await cubit.confirm();

      expect(place?.area, 'Salmiya');
      expect(fakes.resolvePin.calls, hasLength(1));
      expect(cubit.state.confirming, isFalse);
    });

    test('while the map moves there is nothing to confirm', () async {
      final cubit = fakes.cubit();
      addTearDown(cubit.close);
      await cubit.start(languageCode: 'en', findMe: false);
      cubit.cameraMoveStarted();

      expect(await cubit.confirm(), isNull);
    });
  });

  group('camera moves', () {
    test(
      'a searched place: the map flies there and the pin takes its name',
      () async {
        final cubit = fakes.cubit();
        addTearDown(cubit.close);
        await cubit.start(languageCode: 'en', findMe: false);

        cubit.moveTo(const PlaceSpot(location: salmiya, title: 'Marina Mall'));
        expect(cubit.state.camera?.target, salmiya);
        expect(cubit.state.camera?.zoom, AddressPickerState.streetZoom);

        // A whole district: its streets in sight, not one door.
        cubit.moveTo(
          const PlaceSpot(location: jahra, title: 'Jahra', isArea: true),
        );
        expect(cubit.state.camera?.zoom, AddressPickerState.areaZoom);
        cubit.moveTo(const PlaceSpot(location: salmiya, title: 'Marina Mall'));

        cubit
          ..cameraMoveStarted() // the move asked for
          ..cameraIdle(salmiya);
        await settle();
        expect(cubit.state.place?.name, 'Marina Mall');

        cubit
          ..cameraMoveStarted() // the customer drags away
          ..cameraIdle(jahra);
        await settle();
        expect(cubit.state.place?.name, isEmpty);
      },
    );

    test(
      'the search sends the map to the picked place, or to the device',
      () async {
        final cubit = fakes.cubit();
        addTearDown(cubit.close);
        await cubit.start(languageCode: 'en', findMe: false);

        cubit.goTo(
          const PlaceDestination(PlaceSpot(location: jahra, title: 'Jahra')),
        );
        expect(cubit.state.camera?.target, jahra);

        final asked = fakes.locateDevice.calls.length;
        cubit.goTo(const MyLocationDestination());
        await settle();
        expect(fakes.locateDevice.calls, hasLength(asked + 1));
      },
    );

    test('a tap on the map moves the pin there, keeping the zoom', () async {
      final cubit = fakes.cubit();
      addTearDown(cubit.close);
      await cubit.start(languageCode: 'en', findMe: false);
      cubit.mapTapped(jahra);
      expect(cubit.state.camera?.target, jahra);
      expect(cubit.state.camera?.zoom, isNull);
    });

    test('returnTo jumps back to the confirmed pin under its own words, '
        'unless already there', () async {
      const confirmed = PinnedPlace(
        location: salmiya,
        area: 'Salmiya',
        block: '12',
        street: 'Street 5',
        building: '7',
      );
      final cubit = fakes.cubit();
      addTearDown(cubit.close);
      await cubit.start(languageCode: 'en', findMe: false);
      cubit.cameraIdle(jahra);
      await settle();

      cubit.returnTo(confirmed);
      final jump = cubit.state.camera;
      expect(jump?.target, salmiya);
      expect(jump?.glide, isFalse);

      cubit
        ..cameraMoveStarted()
        ..cameraIdle(salmiya);
      await settle();
      expect(cubit.state.pin, PinStatus.ready);
      expect(cubit.state.place, confirmed);
      // The confirmed spot is not read again.
      expect(fakes.resolvePin.calls.map((call) => call.point), [jahra]);

      cubit.returnTo(confirmed);
      expect(cubit.state.camera, jump);
    });

    test('returnTo on the spot drops a read still on its way', () async {
      const confirmed = PinnedPlace(location: salmiya, street: 'Street 5');
      final gate = Completer<void>();
      fakes.resolvePin.gate = gate;
      final cubit = fakes.cubit();
      addTearDown(cubit.close);
      await cubit.start(languageCode: 'en', findMe: false);
      cubit.cameraIdle(salmiya);
      await settle(); // Salmiya is being read

      cubit.returnTo(confirmed);
      gate.complete();
      await settle();

      expect(cubit.state.pin, PinStatus.ready);
      expect(cubit.state.place, confirmed);
    });
  });

  group('"find me"', () {
    for (final (status, notice) in [
      (DeviceLocationStatus.serviceOff, LocationNotice.serviceOff),
      (DeviceLocationStatus.denied, LocationNotice.denied),
      (DeviceLocationStatus.blocked, LocationNotice.blocked),
      (DeviceLocationStatus.unavailable, LocationNotice.unavailable),
    ]) {
      test('$status says $notice once', () async {
        fakes.locateDevice.result = Right(DeviceLocation.missing(status));
        final cubit = fakes.cubit();
        addTearDown(cubit.close);

        await cubit.locate();
        expect(cubit.state.notice, notice);
        expect(cubit.state.locating, isFalse);

        cubit.cameraMoveStarted(); // any next state clears it
        expect(cubit.state.notice, isNull);
      });
    }

    test('the settings that fix it: the device switch or the app', () async {
      final cubit = fakes.cubit();
      addTearDown(cubit.close);
      await cubit.openSettings(LocationNotice.serviceOff);
      await cubit.openSettings(LocationNotice.blocked);
      expect(fakes.openSettings.opened, [
        LocationSettingsTarget.device,
        LocationSettingsTarget.app,
      ]);
    });
  });

  test('a new language reads the address under the pin again', () async {
    final cubit = fakes.cubit();
    addTearDown(cubit.close);
    await cubit.start(languageCode: 'en', findMe: false);
    cubit.cameraIdle(salmiya);
    await settle();

    cubit
      ..languageChanged('en') // the same: nothing
      ..languageChanged('ar');
    await settle();

    expect(fakes.resolvePin.calls.map((call) => call.languageCode), [
      'en',
      'ar',
    ]);
  });
}
