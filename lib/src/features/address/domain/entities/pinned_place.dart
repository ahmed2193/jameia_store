import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/geo_point_entity.dart';
import 'address_parts.dart';

/// What the map pin points at, read back from the map: the parts of an
/// address a courier needs, as far as the geocoder knew them. Every part may
/// be empty — the customer fills in the rest.
class PinnedPlace extends Equatable {
  const PinnedPlace({
    required this.location,
    this.name = '',
    this.area = '',
    this.block = '',
    this.street = '',
    this.building = '',
  });

  /// Only the point: nothing could be read for it (no geocoder, offline).
  const PinnedPlace.at(this.location)
    : name = '',
      area = '',
      block = '',
      street = '',
      building = '';

  final GeoPointEntity location;

  /// A place with a name at the pin (a tower, a mall), when there is one.
  final String name;

  /// The district (Salmiya, Jabriya …).
  final String area;
  final String block;
  final String street;

  /// The house or building number.
  final String building;

  /// What the address form can take from it (the area is the form's city).
  AddressParts get parts => AddressParts(
    city: area,
    block: block,
    street: street,
    building: building,
  );

  /// Nothing but the point is known.
  bool get isBare =>
      name.isEmpty &&
      area.isEmpty &&
      block.isEmpty &&
      street.isEmpty &&
      building.isEmpty;

  /// The same parts at [point] (a spot a step away reads the same).
  PinnedPlace movedTo(GeoPointEntity point) => PinnedPlace(
    location: point,
    name: name,
    area: area,
    block: block,
    street: street,
    building: building,
  );

  /// The same parts, named [name] (a place picked from the search).
  PinnedPlace named(String name) => PinnedPlace(
    location: location,
    name: name.trim(),
    area: area,
    block: block,
    street: street,
    building: building,
  );

  @override
  List<Object?> get props => [location, name, area, block, street, building];
}
