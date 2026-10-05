import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/address_label.dart';
import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/domain/entities/hero_address_entity.dart';
import 'address_field.dart';
import 'address_parts.dart';
import 'building_type.dart';
import 'new_address_seed.dart';
import 'pinned_place.dart';

/// The address form: every value `POST /v1/account/addresses` accepts, as the
/// customer typed it, plus the [buildingType] that shapes the form.
///
/// Limits are the backend's (OpenAPI). On top of them the app requires what a
/// courier needs in Kuwait: block, street, building and an 8-digit mobile,
/// sent as `+965XXXXXXXX`.
class AddressDraft extends Equatable {
  const AddressDraft({
    this.location = GeoPointEntity.kuwaitCity,
    this.hasPin = false,
    this.label = AddressLabel.home,
    this.buildingType = BuildingType.apartment,
    this.city = '',
    this.block = '',
    this.street = '',
    this.building = '',
    this.floor = '',
    this.apartment = '',
    this.phone = '',
    this.notes = '',
    this.isDefault = false,
  });

  /// The form for a new address: the default one when [seed] says so, and
  /// the customer's own number when it is a Kuwait mobile (any other number
  /// would only be refused, so the field starts empty instead).
  factory AddressDraft.seeded(NewAddressSeed seed) {
    final phone = localPhone(seed.customerPhone);
    return AddressDraft(
      isDefault: seed.isDefault,
      phone: phone.length == phoneDigits ? phone : '',
    );
  }

  /// The form for an existing address. An address saved without a pin opens
  /// on [GeoPointEntity.kuwaitCity]; its building type is read from what it stores.
  factory AddressDraft.fromAddress(HeroAddressEntity address) => AddressDraft(
    location: address.location ?? GeoPointEntity.kuwaitCity,
    hasPin: address.location != null,
    label: address.labelKind,
    buildingType: BuildingType.of(address),
    city: address.city,
    block: address.block,
    street: address.street,
    building: address.building,
    floor: address.floor,
    apartment: address.apartment,
    phone: localPhone(address.phone),
    notes: address.notes,
    isDefault: address.isDefault,
  );

  // Backend limits (`POST /v1/account/addresses`).
  static const int maxCityLength = 120;
  static const int maxBlockLength = 32;
  static const int maxStreetLength = 120;
  static const int maxBuildingLength = 32;
  static const int maxFloorLength = 16;
  static const int maxApartmentLength = 16;
  static const int maxNotesLength = 256;
  static const double maxLatitude = 90;
  static const double maxLongitude = 180;

  /// Kuwaiti mobile: 8 local digits behind the `965` country code.
  static const int phoneDigits = 8;
  static const String phoneCountryCode = '965';
  static const int maxPhoneInputLength = 16;

  static final RegExp _nonDigits = RegExp(r'\D');

  final GeoPointEntity location;

  /// [location] is a real pin, not the stand-in of an address that never
  /// had one (a new one, or one saved without lat / lng).
  final bool hasPin;
  final AddressLabel label;

  /// Not sent: a house has no floor or flat, so the form hides them.
  final BuildingType buildingType;

  final String city;
  final String block;
  final String street;
  final String building;
  final String floor;
  final String apartment;

  /// As typed: the local digits, possibly with the country code.
  final String phone;
  final String notes;
  final bool isDefault;

  static bool isRequired(AddressField field) => switch (field) {
    AddressField.city ||
    AddressField.block ||
    AddressField.street ||
    AddressField.building ||
    AddressField.phone => true,
    AddressField.floor || AddressField.apartment || AddressField.notes => false,
  };

  /// The longest value the form accepts for [field].
  static int maxLengthOf(AddressField field) => switch (field) {
    AddressField.city => maxCityLength,
    AddressField.block => maxBlockLength,
    AddressField.street => maxStreetLength,
    AddressField.building => maxBuildingLength,
    AddressField.floor => maxFloorLength,
    AddressField.apartment => maxApartmentLength,
    AddressField.phone => maxPhoneInputLength,
    AddressField.notes => maxNotesLength,
  };

  /// [raw] as local digits: formatting dropped and a leading `965` removed
  /// from an 11-digit number.
  static String localPhone(String raw) {
    final digits = raw.replaceAll(_nonDigits, '');
    final withCountryCode = phoneCountryCode.length + phoneDigits;
    if (digits.length == withCountryCode &&
        digits.startsWith(phoneCountryCode)) {
      return digits.substring(phoneCountryCode.length);
    }
    return digits;
  }

  /// The phone as the backend stores it (`+965XXXXXXXX`).
  String get wirePhone => '+$phoneCountryCode${localPhone(phone)}';

  String valueOf(AddressField field) => switch (field) {
    AddressField.city => city,
    AddressField.block => block,
    AddressField.street => street,
    AddressField.building => building,
    AddressField.floor => floor,
    AddressField.apartment => apartment,
    AddressField.phone => phone,
    AddressField.notes => notes,
  };

  AddressFieldError? errorFor(AddressField field) {
    final value = valueOf(field).trim();
    if (value.isEmpty) {
      return isRequired(field) ? AddressFieldError.required : null;
    }
    if (field == AddressField.phone) {
      return localPhone(value).length == phoneDigits
          ? null
          : AddressFieldError.invalidPhone;
    }
    return value.length > maxLengthOf(field) ? AddressFieldError.tooLong : null;
  }

  bool get hasValidLocation =>
      location.lat.abs() <= maxLatitude && location.lng.abs() <= maxLongitude;

  bool get isValid =>
      hasValidLocation &&
      AddressField.values.every((field) => errorFor(field) == null);

  AddressDraft withField(AddressField field, String value) => switch (field) {
    AddressField.city => copyWith(city: value),
    AddressField.block => copyWith(block: value),
    AddressField.street => copyWith(street: value),
    AddressField.building => copyWith(building: value),
    AddressField.floor => copyWith(floor: value),
    AddressField.apartment => copyWith(apartment: value),
    AddressField.phone => copyWith(phone: value),
    AddressField.notes => copyWith(notes: value),
  };

  /// [parts] trimmed and cut to the backend limits: what [pinnedAt] writes.
  static AddressParts _fit(AddressParts parts) {
    String cut(String part, int maxLength) {
      final value = part.trim();
      return value.length > maxLength ? value.substring(0, maxLength) : value;
    }

    return AddressParts(
      city: cut(parts.city, maxCityLength),
      block: cut(parts.block, maxBlockLength),
      street: cut(parts.street, maxStreetLength),
      building: cut(parts.building, maxBuildingLength),
    );
  }

  /// Closer than this, a new pin is on the same building: a part the map
  /// could not read there keeps what the form holds.
  static const double samePlaceMeters = 30;

  /// The pin moved to [location] and the map read [parts] there: the address
  /// follows the pin. Area, block, street and building become what the map
  /// read at the new spot; a part it could not read is cleared — the old one
  /// told of another place — unless the pin only moved on the same building
  /// ([samePlaceMeters]), where it stays as it was. An address's first pin
  /// ([hasPin] false) moves nothing: it only fills the parts the form lacks
  /// ([filledFrom]), the saved ones describing that very address. The
  /// floor, the flat, the directions and the contact are the customer's own
  /// and stay.
  AddressDraft pinnedAt(
    GeoPointEntity location, {
    AddressParts parts = AddressParts.none,
  }) {
    if (!hasPin) {
      return filledFrom(parts).copyWith(location: location, hasPin: true);
    }
    final read = _fit(parts);
    final samePlace = this.location.metersTo(location) < samePlaceMeters;
    String follow(String current, String part) =>
        part.isNotEmpty || !samePlace ? part : current;

    return copyWith(
      location: location,
      city: follow(city, read.city),
      block: follow(block, read.block),
      street: follow(street, read.street),
      building: follow(building, read.building),
    );
  }

  /// [parts] read at the pin itself fill only the parts still empty: an
  /// address's first pin, or a read that came after Confirm stopped waiting
  /// for it.
  AddressDraft filledFrom(AddressParts parts) {
    final read = _fit(parts);
    String fill(String current, String part) =>
        current.trim().isEmpty ? part : current;

    return copyWith(
      city: fill(city, read.city),
      block: fill(block, read.block),
      street: fill(street, read.street),
      building: fill(building, read.building),
    );
  }

  /// The form for a [type] building: a house drops the floor and the flat
  /// (no hidden value is ever saved).
  AddressDraft withBuildingType(BuildingType type) => type.hasUnits
      ? copyWith(buildingType: type)
      : copyWith(buildingType: type, floor: '', apartment: '');

  /// The pin as the form holds it — its point and the parts filled in: the
  /// map picker opens on it when an address is edited.
  PinnedPlace get pinnedPlace => PinnedPlace(
    location: location,
    area: city.trim(),
    block: block.trim(),
    street: street.trim(),
    building: building.trim(),
  );

  AddressDraft copyWith({
    GeoPointEntity? location,
    bool? hasPin,
    AddressLabel? label,
    BuildingType? buildingType,
    String? city,
    String? block,
    String? street,
    String? building,
    String? floor,
    String? apartment,
    String? phone,
    String? notes,
    bool? isDefault,
  }) => AddressDraft(
    location: location ?? this.location,
    hasPin: hasPin ?? this.hasPin,
    label: label ?? this.label,
    buildingType: buildingType ?? this.buildingType,
    city: city ?? this.city,
    block: block ?? this.block,
    street: street ?? this.street,
    building: building ?? this.building,
    floor: floor ?? this.floor,
    apartment: apartment ?? this.apartment,
    phone: phone ?? this.phone,
    notes: notes ?? this.notes,
    isDefault: isDefault ?? this.isDefault,
  );

  @override
  List<Object?> get props => [
    location,
    hasPin,
    label,
    buildingType,
    city,
    block,
    street,
    building,
    floor,
    apartment,
    phone,
    notes,
    isDefault,
  ];
}
