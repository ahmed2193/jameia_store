import 'package:equatable/equatable.dart';

import 'address_label.dart';
import 'geo_point_entity.dart';

/// A saved delivery address, shaped like the jm3eia API row
/// (`GET / POST / PATCH /v1/account/addresses`).
///
/// Optional wire fields are empty strings here, never `null`, so widgets and
/// update diffs compare plain values. [label] is the raw wire text;
/// [labelKind] is the tag the app understands.
class JameiaAddressEntity extends Equatable {
  const JameiaAddressEntity({
    required this.id,
    required this.label,
    this.city = '',
    this.governorateNo = '',
    this.areaId = '',
    this.block = '',
    this.street = '',
    this.building = '',
    this.floor = '',
    this.apartment = '',
    this.phone = '',
    this.notes = '',
    this.location,
    this.isDefault = false,
  });

  /// Mongo id (`_id`).
  final String id;

  /// Raw tag text, e.g. `Home`.
  final String label;

  /// Area name (reverse-geocoded when the address was pinned).
  final String city;
  final String governorateNo;
  final String areaId;
  final String block;
  final String street;
  final String building;
  final String floor;
  final String apartment;

  /// Contact phone for the courier, as stored (E.164 when the app wrote it).
  final String phone;
  final String notes;

  /// The map pin; `null` when the address was saved without coordinates.
  final GeoPointEntity? location;
  final bool isDefault;

  AddressLabel get labelKind => AddressLabel.fromWire(label);

  /// The label text another client wrote that matches no app tag (e.g.
  /// `Mom's house`), or `null` when [labelKind] already says it all.
  String? get customLabel {
    final text = label.trim();
    if (labelKind != AddressLabel.other || text.isEmpty) return null;
    final isOtherToken =
        text.toLowerCase() == AddressLabel.other.wireValue.toLowerCase();
    return isOtherToken ? null : text;
  }

  JameiaAddressEntity copyWith({bool? isDefault}) => JameiaAddressEntity(
    id: id,
    label: label,
    city: city,
    governorateNo: governorateNo,
    areaId: areaId,
    block: block,
    street: street,
    building: building,
    floor: floor,
    apartment: apartment,
    phone: phone,
    notes: notes,
    location: location,
    isDefault: isDefault ?? this.isDefault,
  );

  @override
  List<Object?> get props => [
    id,
    label,
    city,
    governorateNo,
    areaId,
    block,
    street,
    building,
    floor,
    apartment,
    phone,
    notes,
    location,
    isDefault,
  ];
}
