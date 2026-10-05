// Fakes for the map picker and the place search: every use case answers
// what the test set, records its calls and can be held on a gate.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/usecase/usecase.dart';
import 'package:hero_mart/src/features/address/domain/entities/device_location.dart';
import 'package:hero_mart/src/features/address/domain/entities/pinned_place.dart';
import 'package:hero_mart/src/features/address/domain/entities/place_spot.dart';
import 'package:hero_mart/src/features/address/domain/entities/place_suggestion.dart';
import 'package:hero_mart/src/features/address/domain/entities/service_area.dart';
import 'package:hero_mart/src/features/address/domain/usecases/end_place_search_usecase.dart';
import 'package:hero_mart/src/features/address/domain/usecases/get_delivery_areas_usecase.dart';
import 'package:hero_mart/src/features/address/domain/usecases/get_last_known_location_usecase.dart';
import 'package:hero_mart/src/features/address/domain/usecases/get_service_area_usecase.dart';
import 'package:hero_mart/src/features/address/domain/usecases/locate_device_usecase.dart';
import 'package:hero_mart/src/features/address/domain/usecases/locate_place_usecase.dart';
import 'package:hero_mart/src/features/address/domain/usecases/open_location_settings_usecase.dart';
import 'package:hero_mart/src/features/address/domain/usecases/resolve_pin_usecase.dart';
import 'package:hero_mart/src/features/address/domain/usecases/search_places_usecase.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/address_picker_cubit.dart';

/// Salmiya — inside the test area.
const GeoPointEntity salmiya = GeoPointEntity(lat: 29.334, lng: 48.078);

/// Jahra — inside the test area too.
const GeoPointEntity jahra = GeoPointEntity(lat: 29.3375, lng: 47.6581);

/// Marrakesh — far outside it.
const GeoPointEntity marrakesh = GeoPointEntity(lat: 31.63, lng: -8.0);

/// A box around Kuwait.
const ServiceArea testArea = ServiceArea([
  [
    GeoPointEntity(lat: 28.5, lng: 46.5),
    GeoPointEntity(lat: 30.1, lng: 46.5),
    GeoPointEntity(lat: 30.1, lng: 48.5),
    GeoPointEntity(lat: 28.5, lng: 48.5),
  ],
]);

mixin _Gated {
  /// While set and not completed, every call waits for it.
  Completer<void>? gate;

  Future<void> waitGate() async {
    final pending = gate;
    if (pending != null) await pending.future;
  }
}

class FakeResolvePinUseCase with _Gated implements ResolvePinUseCase {
  /// The answer for a point; the bare point when unset.
  PinnedPlace Function(GeoPointEntity point)? answer;
  Failure? failure;
  final List<ResolvePinParams> calls = [];

  @override
  Future<Either<Failure, PinnedPlace>> call(ResolvePinParams params) async {
    calls.add(params);
    await waitGate();
    final failed = failure;
    if (failed != null) return Left(failed);
    final read = answer;
    return Right(
      read == null ? PinnedPlace.at(params.point) : read(params.point),
    );
  }
}

class FakeGetLastKnownLocationUseCase implements GetLastKnownLocationUseCase {
  Either<Failure, DeviceLocation> result = const Right(
    DeviceLocation.missing(DeviceLocationStatus.unavailable),
  );

  @override
  Future<Either<Failure, DeviceLocation>> call(NoParams params) async => result;
}

class FakeLocateDeviceUseCase with _Gated implements LocateDeviceUseCase {
  Either<Failure, DeviceLocation> result = const Right(
    DeviceLocation.missing(DeviceLocationStatus.unavailable),
  );
  final List<LocateDeviceParams> calls = [];

  @override
  Future<Either<Failure, DeviceLocation>> call(
    LocateDeviceParams params,
  ) async {
    calls.add(params);
    await waitGate();
    return result;
  }
}

class FakeOpenLocationSettingsUseCase implements OpenLocationSettingsUseCase {
  final List<LocationSettingsTarget> opened = [];

  @override
  Future<Either<Failure, bool>> call(OpenLocationSettingsParams params) async {
    opened.add(params.target);
    return const Right(true);
  }
}

class FakeGetServiceAreaUseCase implements GetServiceAreaUseCase {
  Either<Failure, ServiceArea> result = const Right(testArea);

  @override
  Future<Either<Failure, ServiceArea>> call(NoParams params) async => result;
}

class FakeGetDeliveryAreasUseCase implements GetDeliveryAreasUseCase {
  Either<Failure, List<PlaceSuggestion>> result = const Right([]);
  final List<String> asked = [];
  final List<GeoPointEntity?> nearAsked = [];

  @override
  Either<Failure, List<PlaceSuggestion>> call(DeliveryAreasParams params) {
    asked.add(params.languageCode);
    nearAsked.add(params.near);
    return result;
  }
}

class FakeSearchPlacesUseCase with _Gated implements SearchPlacesUseCase {
  Either<Failure, List<PlaceSuggestion>> result = const Right([]);
  final List<SearchPlacesParams> calls = [];

  @override
  Future<Either<Failure, List<PlaceSuggestion>>> call(
    SearchPlacesParams params,
  ) async {
    calls.add(params);
    await waitGate();
    return result;
  }
}

class FakeLocatePlaceUseCase with _Gated implements LocatePlaceUseCase {
  Either<Failure, PlaceSpot> result = const Right(
    PlaceSpot(location: salmiya, title: 'Salmiya'),
  );
  final List<LocatePlaceParams> calls = [];

  @override
  Future<Either<Failure, PlaceSpot>> call(LocatePlaceParams params) async {
    calls.add(params);
    await waitGate();
    return result;
  }
}

class FakeEndPlaceSearchUseCase implements EndPlaceSearchUseCase {
  int calls = 0;

  @override
  Either<Failure, Unit> call(NoParams params) {
    calls++;
    return const Right(unit);
  }
}

/// The picker's use cases together, and a cubit built on them.
class PickerFakes {
  final FakeResolvePinUseCase resolvePin = FakeResolvePinUseCase();
  final FakeGetLastKnownLocationUseCase lastKnown =
      FakeGetLastKnownLocationUseCase();
  final FakeLocateDeviceUseCase locateDevice = FakeLocateDeviceUseCase();
  final FakeOpenLocationSettingsUseCase openSettings =
      FakeOpenLocationSettingsUseCase();
  final FakeGetServiceAreaUseCase serviceArea = FakeGetServiceAreaUseCase();

  AddressPickerCubit cubit({PinnedPlace? pinned}) => AddressPickerCubit(
    resolvePin: resolvePin,
    lastKnown: lastKnown,
    locateDevice: locateDevice,
    openSettings: openSettings,
    serviceArea: serviceArea,
    pinned: pinned,
  );
}
