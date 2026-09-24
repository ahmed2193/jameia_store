import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/address_label.dart';
import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../core/domain/entities/jameia_address_entity.dart';
import 'address_field.dart';

/// The address form: every value `POST /v1/account/addresses` accepts, as the
/// customer typed it.
///
/// Limits are the backend's (OpenAPI). On top of them the app requires what a
/// courier needs in Kuwait: block, street, building and an 8-digit mobile,
/// sent as `+965XXXXXXXX`.
class AddressDraft extends Equatable {
  const AddressDraft({
    this.location = kuwaitCity,
    this.label = AddressLabel.home,
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

  /// The form for an existing address. An address saved without a pin opens
  /// on [kuwaitCity].
  factory AddressDraft.fromAddress(JameiaAddressEntity address) => AddressDraft(
    location: address.location ?? kuwaitCity,
    label: address.labelKind,
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

  /// Map start for a new address (Kuwait City).
  static const GeoPointEntity kuwaitCity = GeoPointEntity(
    lat: 29.3759,
    lng: 47.9774,
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
  final AddressLabel label;
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

  /// The pin moved to [location]; the reverse-geocoded parts fill their fields.
  /// An empty resolved part keeps what the form already holds, and a long one
  /// is cut to the backend limit.
  AddressDraft pinnedAt(
    GeoPointEntity location, {
    String city = '',
    String block = '',
    String street = '',
    String building = '',
    String apartment = '',
  }) {
    String resolved(String part, String current, int maxLength) {
      final value = part.trim();
      if (value.isEmpty) return current;
      return value.length > maxLength ? value.substring(0, maxLength) : value;
    }

    return copyWith(
      location: location,
      city: resolved(city, this.city, maxCityLength),
      block: resolved(block, this.block, maxBlockLength),
      street: resolved(street, this.street, maxStreetLength),
      building: resolved(building, this.building, maxBuildingLength),
      apartment: resolved(apartment, this.apartment, maxApartmentLength),
    );
  }

  AddressDraft copyWith({
    GeoPointEntity? location,
    AddressLabel? label,
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
    label: label ?? this.label,
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
    label,
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
