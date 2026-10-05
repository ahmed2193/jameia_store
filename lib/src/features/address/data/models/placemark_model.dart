/// One answer of the device's geocoder for a point, in the language asked
/// for. Every field may be empty: geocoders know more in some streets than
/// in others.
class PlacemarkModel {
  const PlacemarkModel({
    this.name = '',
    this.street = '',
    this.thoroughfare = '',
    this.subThoroughfare = '',
    this.subLocality = '',
    this.locality = '',
    this.subAdministrativeArea = '',
    this.administrativeArea = '',
    this.country = '',
  });

  /// The geocoder's own strings, cleaned: trimmed, without the invisible
  /// direction marks some carry ("الكويت" may end in one), a missing one
  /// empty.
  factory PlacemarkModel.fromGeocoder({
    String? name,
    String? street,
    String? thoroughfare,
    String? subThoroughfare,
    String? subLocality,
    String? locality,
    String? subAdministrativeArea,
    String? administrativeArea,
    String? country,
  }) => PlacemarkModel(
    name: _clean(name),
    street: _clean(street),
    thoroughfare: _clean(thoroughfare),
    subThoroughfare: _clean(subThoroughfare),
    subLocality: _clean(subLocality),
    locality: _clean(locality),
    subAdministrativeArea: _clean(subAdministrativeArea),
    administrativeArea: _clean(administrativeArea),
    country: _clean(country),
  );

  static final RegExp _directionMarks = RegExp(
    '[\u200E\u200F\u061C\u202A-\u202E\u2066-\u2069]',
  );

  static String _clean(String? value) =>
      value?.replaceAll(_directionMarks, '').trim() ?? '';

  /// A named place, or the street line again.
  final String name;

  /// The street line as the geocoder prints it (may hold the number).
  final String street;
  final String thoroughfare;

  /// The house / building number.
  final String subThoroughfare;

  /// The district (Kuwait's "area").
  final String subLocality;
  final String locality;
  final String subAdministrativeArea;

  /// The governorate ("الجهراء").
  final String administrativeArea;
  final String country;
}
