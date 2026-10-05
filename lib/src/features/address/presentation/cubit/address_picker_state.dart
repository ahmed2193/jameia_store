import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../domain/entities/pinned_place.dart';

/// Where the map pin stands.
enum PinStatus {
  /// The map moves under the pin: it is lifted, nothing can be confirmed.
  moving,

  /// Settled inside the delivery area; the address under it is being read.
  resolving,

  /// Settled inside the delivery area and read ([AddressPickerState.place];
  /// it may know nothing but the point).
  ready,

  /// Settled outside the delivery area.
  outside,
}

/// Why "find me" could not move the map (a one-shot the page says once).
enum LocationNotice { serviceOff, denied, blocked, unavailable }

/// A camera move the page should make: a new [id] is a new move.
class MapCameraMove extends Equatable {
  const MapCameraMove({
    required this.id,
    required this.target,
    this.zoom,
    this.glide = true,
  });

  final int id;
  final GeoPointEntity target;

  /// `null` keeps the zoom.
  final double? zoom;

  /// Glide there, or jump (the map's first position).
  final bool glide;

  @override
  List<Object?> get props => [id, target, zoom, glide];
}

/// The map picker: where the pin points, what is there, and the camera
/// moves asked of the map.
class AddressPickerState extends Equatable {
  const AddressPickerState({
    required this.target,
    required this.openingZoom,
    this.pin = PinStatus.resolving,
    this.place,
    this.camera,
    this.locating = false,
    this.confirming = false,
    this.showsMyLocation = false,
    this.notice,
    this.opened = true,
  });

  /// A door: the customer's own position, or a saved pin to adjust.
  static const double doorZoom = 18;

  /// A spot: close enough to set the pin on one building.
  static const double streetZoom = 17;

  /// A district picked from the list: its streets in sight.
  static const double areaZoom = 15;

  /// The whole city, for a map that does not know where the customer is.
  static const double cityZoom = 11.5;

  /// Where the pin points (the map's middle once it settled).
  final GeoPointEntity target;

  /// The zoom the map opens at.
  final double openingZoom;

  /// Where the map opens is known: the map may be made. A picker with no pin
  /// to show waits for the customer's position (or gives up on it).
  final bool opened;
  final PinStatus pin;

  /// What is under the pin; `null` while moving, reading or outside.
  final PinnedPlace? place;

  /// The latest camera move asked for.
  final MapCameraMove? camera;

  /// Finding the device's position.
  final bool locating;

  /// Confirm waits for the address under the pin.
  final bool confirming;

  /// The "you are here" dot (the app may read the location).
  final bool showsMyLocation;

  /// Transient — cleared on every [copyWith].
  final LocationNotice? notice;

  /// The map is up and its pin settled inside the area: Confirm may go
  /// ahead.
  bool get canConfirm =>
      opened && (pin == PinStatus.ready || pin == PinStatus.resolving);

  AddressPickerState copyWith({
    GeoPointEntity? target,
    double? openingZoom,
    bool? opened,
    PinStatus? pin,
    PinnedPlace? place,
    bool clearPlace = false,
    MapCameraMove? camera,
    bool? locating,
    bool? confirming,
    bool? showsMyLocation,
    LocationNotice? notice,
  }) => AddressPickerState(
    target: target ?? this.target,
    openingZoom: openingZoom ?? this.openingZoom,
    opened: opened ?? this.opened,
    pin: pin ?? this.pin,
    place: clearPlace ? null : place ?? this.place,
    camera: camera ?? this.camera,
    locating: locating ?? this.locating,
    confirming: confirming ?? this.confirming,
    showsMyLocation: showsMyLocation ?? this.showsMyLocation,
    notice: notice,
  );

  @override
  List<Object?> get props => [
    target,
    openingZoom,
    opened,
    pin,
    place,
    camera,
    locating,
    confirming,
    showsMyLocation,
    notice,
  ];
}
