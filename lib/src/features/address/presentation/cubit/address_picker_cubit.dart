import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/device_location.dart';
import '../../domain/entities/map_destination.dart';
import '../../domain/entities/pinned_place.dart';
import '../../domain/entities/place_spot.dart';
import '../../domain/entities/service_area.dart';
import '../../domain/usecases/get_last_known_location_usecase.dart';
import '../../domain/usecases/get_service_area_usecase.dart';
import '../../domain/usecases/locate_device_usecase.dart';
import '../../domain/usecases/open_location_settings_usecase.dart';
import '../../domain/usecases/resolve_pin_usecase.dart';
import 'address_picker_state.dart';

/// The map picker (page-scoped): a fixed pin over a map that moves under
/// it, Google-Maps style.
///
/// * The map tells it when it starts moving ([cameraMoveStarted]) and where
///   it settled ([cameraIdle]); between the two the pin is lifted. Settled
///   outside the delivery area it says so at once; inside, the address
///   under the pin is read [settleDelay] later (a quick second drag reads
///   nothing), and an answer for a spot the map has left is dropped. One
///   read at a time — geocoders throttle an app that asks in bursts — and a
///   nudge of a step or two keeps the address already read.
/// * It asks the map to move ([AddressPickerState.camera]): to the device's
///   position, to a searched place (shown under the place's name), to a
///   tapped spot.
/// * Opening on an address being edited it shows that address's pin, read
///   already ([pinned]). With no pin (a new address, or a saved one that
///   never had one) the map is made only once it knows where to open
///   ([AddressPickerState.opened]): on the customer, close up — the last
///   known position, else a fresh fix — or, when the device cannot tell,
///   on Kuwait City. A fresh fix after the last known position glides
///   there, unless the customer moved the map meanwhile; a place picked
///   in the search before anything was found opens the map on that place.
class AddressPickerCubit extends Cubit<AddressPickerState>
    with SafeCubitMixin<AddressPickerState> {
  AddressPickerCubit({
    required this._resolvePin,
    required this._lastKnown,
    required this._locateDevice,
    required this._openSettings,
    required this._serviceArea,
    PinnedPlace? pinned,
  }) : super(
         AddressPickerState(
           target: pinned?.location ?? GeoPointEntity.kuwaitCity,
           openingZoom: pinned == null
               ? AddressPickerState.cityZoom
               : AddressPickerState.doorZoom,
           // An address with a pin opens on it at once, already read; one
           // without waits to find the customer.
           pin: pinned == null ? PinStatus.resolving : PinStatus.ready,
           place: pinned,
           opened: pinned != null,
         ),
       );

  final ResolvePinUseCase _resolvePin;
  final GetLastKnownLocationUseCase _lastKnown;
  final LocateDeviceUseCase _locateDevice;
  final OpenLocationSettingsUseCase _openSettings;
  final GetServiceAreaUseCase _serviceArea;

  /// The pause after the map settles before the address is read.
  static const Duration settleDelay = Duration(milliseconds: 250);

  /// The longest Confirm waits for the address under the pin.
  static const Duration confirmWait = Duration(seconds: 2);

  /// Closer than this, two points are the same spot.
  static const double _sameSpotMeters = 1;

  /// A searched place keeps its name while the pin stays this close to it.
  static const double _namedSpotMeters = 30;

  /// A pin moved less than this keeps the address read for it.
  static const double _sameAddressMeters = 3;

  ServiceArea? _area;
  String _languageCode = _defaultLanguage;
  Timer? _settle;
  Future<void>? _reading;
  bool _readInFlight = false;

  /// The spot to read once the read in flight answers.
  ({GeoPointEntity point, int generation})? _queued;

  /// The last address read, in the current language: a nudge of a step
  /// shows it again at once (no pause, no loading label). The repository's
  /// memo is another matter — it spares the geocoder across pickers.
  PinnedPlace? _lastRead;
  int _generation = 0;
  int _cameraMoves = 0;

  /// Moves this cubit asked of the map that have not started yet (any left
  /// over when the map settles never will).
  int _movesAsked = 0;

  /// The customer moved the map since the picker opened.
  bool _customerMoved = false;

  /// The place last picked from the search, and where.
  ({GeoPointEntity at, String name})? _searched;

  static const String _defaultLanguage = 'en';

  /// Opens the picker in [languageCode]. With no pin to show ([findMe]) the
  /// map opens on the device's last known position, else on a fresh fix,
  /// else on Kuwait City.
  Future<void> start({
    required String languageCode,
    required bool findMe,
  }) async {
    _languageCode = languageCode;
    final area = _serviceArea(const NoParams());
    final last = await _lastKnown(const NoParams());
    // Known before the map opens: its first verdict is the right one.
    _area = (await area).fold((_) => null, (area) => area);
    final known = last.fold((_) => null, (location) => location);
    if (known != null) {
      safeEmit(state.copyWith(showsMyLocation: known.isAllowed));
      final point = known.point;
      if (findMe && point != null && !_customerMoved) {
        _moveCamera(point, zoom: AddressPickerState.doorZoom, glide: false);
      }
    }
    if (findMe) await locate(quiet: true);
    // Nothing found, or nobody to find: the city.
    if (!state.opened) {
      _moveCamera(GeoPointEntity.kuwaitCity, zoom: AddressPickerState.cityZoom);
    }
  }

  /// The app's language changed: the address under the pin is read again.
  void languageChanged(String languageCode) {
    if (languageCode == _languageCode) return;
    _languageCode = languageCode;
    _lastRead = null;
    if (state.pin == PinStatus.ready) cameraIdle(state.target, force: true);
  }

  /// "Find me": the map glides to the device's position. [quiet] (the
  /// picker opening) says nothing when it cannot, and never pulls the map
  /// away from where the customer already took it.
  Future<void> locate({bool quiet = false}) async {
    if (state.locating) return;
    safeEmit(state.copyWith(locating: true));
    final result = await _locateDevice(const LocateDeviceParams(ask: true));
    result.fold(
      (_) => safeEmit(
        state.copyWith(
          locating: false,
          notice: quiet ? null : LocationNotice.unavailable,
        ),
      ),
      (location) {
        final point = location.point;
        safeEmit(
          state.copyWith(
            locating: false,
            showsMyLocation: location.isAllowed,
            notice: point != null || quiet ? null : _noticeFor(location),
          ),
        );
        if (point == null || (quiet && _customerMoved)) return;
        if (!state.opened || point.metersTo(state.target) > _sameSpotMeters) {
          _moveCamera(point, zoom: AddressPickerState.doorZoom);
        }
      },
    );
  }

  /// Opens the settings screen that can fix [notice].
  Future<void> openSettings(LocationNotice notice) async {
    final target = notice == LocationNotice.serviceOff
        ? LocationSettingsTarget.device
        : LocationSettingsTarget.app;
    await _openSettings(OpenLocationSettingsParams(target));
  }

  /// The customer picked [spot] in the search: the map flies there and the
  /// pin goes by the place's name.
  void moveTo(PlaceSpot spot) {
    // The customer's choice: a fix still on its way leaves the map there.
    _customerMoved = true;
    _searched = (at: spot.location, name: spot.title);
    _moveCamera(
      spot.location,
      zoom: spot.isArea
          ? AddressPickerState.areaZoom
          : AddressPickerState.streetZoom,
    );
  }

  /// The search answered [destination]: the map goes to the picked place,
  /// or to the device's position.
  void goTo(MapDestination destination) {
    switch (destination) {
      case PlaceDestination(:final spot):
        moveTo(spot);
      case MyLocationDestination():
        unawaited(locate());
    }
  }

  /// A tap on the map: the pin goes there.
  void mapTapped(GeoPointEntity point) => _moveCamera(point);

  /// The map jumps back to [place] (the pin as last confirmed) while it is
  /// out of sight, so it opens there next time — under the confirmed words,
  /// not read again.
  void returnTo(PinnedPlace place) {
    final point = place.location;
    _searched = null;
    if (!place.isBare) _lastRead = place;
    if (state.pin == PinStatus.moving ||
        state.target.metersTo(point) >= _sameSpotMeters) {
      _moveCamera(point, zoom: AddressPickerState.streetZoom, glide: false);
      return;
    }
    // Already there: no read still on its way overwrites the words.
    _settle?.cancel();
    _generation++;
    safeEmit(state.copyWith(target: point, pin: PinStatus.ready, place: place));
  }

  void cameraMoveStarted() {
    _settle?.cancel();
    _generation++;
    if (_movesAsked > 0) {
      _movesAsked--;
    } else {
      _customerMoved = true;
      _searched = null;
    }
    if (state.pin != PinStatus.moving || state.place != null) {
      safeEmit(state.copyWith(pin: PinStatus.moving, clearPlace: true));
    }
  }

  /// The map settled with its middle on [point]. [force]: read it again
  /// even when nothing moved.
  void cameraIdle(GeoPointEntity point, {bool force = false}) {
    _movesAsked = 0;
    final samePoint = state.target.metersTo(point) < _sameSpotMeters;
    final waiting = (_settle?.isActive ?? false) || _readInFlight;
    if (!force && samePoint && state.pin == PinStatus.resolving && waiting) {
      return;
    }
    final place = state.place;
    if (!force &&
        place != null &&
        state.pin == PinStatus.ready &&
        place.location.metersTo(point) < _sameSpotMeters) {
      return;
    }
    _settle?.cancel();
    final generation = ++_generation;
    final area = _area;
    if (area != null && !area.contains(point)) {
      safeEmit(
        state.copyWith(target: point, pin: PinStatus.outside, clearPlace: true),
      );
      return;
    }
    final last = _lastRead;
    if (!force &&
        last != null &&
        last.location.metersTo(point) < _sameAddressMeters) {
      safeEmit(
        state.copyWith(
          target: point,
          pin: PinStatus.ready,
          place: _named(last.movedTo(point)),
        ),
      );
      return;
    }
    safeEmit(
      state.copyWith(target: point, pin: PinStatus.resolving, clearPlace: true),
    );
    _settle = Timer(settleDelay, () => _read(point, generation));
  }

  /// The pin as confirmed, once its address is read (at most [confirmWait]);
  /// `null` while it moves or lies outside the delivery area.
  Future<PinnedPlace?> confirm() async {
    if (!state.canConfirm || state.confirming) return null;
    if (state.pin == PinStatus.resolving) {
      final generation = _generation;
      safeEmit(state.copyWith(confirming: true));
      if (_settle?.isActive ?? false) {
        _settle?.cancel();
        _read(state.target, generation);
      }
      await _answered(generation).timeout(confirmWait, onTimeout: () {});
      if (isClosed) return null;
      safeEmit(state.copyWith(confirming: false));
      if (generation != _generation) return null;
    }
    return state.place ?? PinnedPlace.at(state.target);
  }

  void _read(GeoPointEntity point, int generation) {
    if (_readInFlight) {
      _queued = (point: point, generation: generation);
      return;
    }
    _reading = _readNow(point, generation);
  }

  Future<void> _readNow(GeoPointEntity point, int generation) async {
    _readInFlight = true;
    final result = await _resolvePin(
      ResolvePinParams(point: point, languageCode: _languageCode),
    );
    _readInFlight = false;
    final queued = _queued;
    _queued = null;
    if (queued != null && queued.generation == _generation && !isClosed) {
      _read(queued.point, queued.generation);
    }
    if (generation != _generation) return;
    final place = result.fold((_) => PinnedPlace.at(point), (read) => read);
    if (!place.isBare) _lastRead = place;
    safeEmit(state.copyWith(pin: PinStatus.ready, place: _named(place)));
  }

  /// Completes once the pin of [generation] is read, the map moved on, or
  /// no read is left to wait for.
  Future<void> _answered(int generation) async {
    var reading = _reading;
    while (reading != null &&
        !isClosed &&
        generation == _generation &&
        state.pin == PinStatus.resolving) {
      await reading;
      if (identical(reading, _reading)) return;
      reading = _reading;
    }
  }

  /// [place] under the searched place's name, while the pin stays on it.
  PinnedPlace _named(PinnedPlace place) {
    final searched = _searched;
    if (searched == null ||
        searched.at.metersTo(place.location) > _namedSpotMeters) {
      return place;
    }
    return place.named(searched.name);
  }

  void _moveCamera(GeoPointEntity point, {double? zoom, bool glide = true}) {
    if (!state.opened) {
      // No map yet: it opens there.
      safeEmit(
        state.copyWith(
          target: point,
          openingZoom: zoom ?? state.openingZoom,
          opened: true,
        ),
      );
      return;
    }
    _movesAsked++;
    safeEmit(
      state.copyWith(
        camera: MapCameraMove(
          id: ++_cameraMoves,
          target: point,
          zoom: zoom,
          glide: glide,
        ),
      ),
    );
  }

  static LocationNotice _noticeFor(DeviceLocation location) =>
      switch (location.status) {
        DeviceLocationStatus.serviceOff => LocationNotice.serviceOff,
        DeviceLocationStatus.denied => LocationNotice.denied,
        DeviceLocationStatus.blocked => LocationNotice.blocked,
        DeviceLocationStatus.found ||
        DeviceLocationStatus.unavailable => LocationNotice.unavailable,
      };

  @override
  Future<void> close() {
    _settle?.cancel();
    return super.close();
  }
}
