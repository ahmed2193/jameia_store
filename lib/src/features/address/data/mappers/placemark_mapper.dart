import '../../../../core/domain/entities/geo_point_entity.dart';
import '../../domain/entities/pinned_place.dart';
import '../models/placemark_model.dart';

/// Reads a Kuwait address out of the geocoder's answers for one point. The
/// answers go from the most precise to the widest, so each part is the first
/// one any answer gives; the street and its number come from one answer, so
/// a number never lands on another street. A road the map has no name for
/// ("Unnamed Road") is no street, and a district, a governorate or the
/// country is no place name.
extension PlacemarkListMapper on List<PlacemarkModel> {
  PinnedPlace toPinnedPlace(GeoPointEntity point) {
    if (isEmpty) return PinnedPlace.at(point);
    final withStreet = where((mark) => _isStreet(mark.thoroughfare));
    final streetMark = withStreet.isEmpty ? null : withStreet.first;
    final area = _first(
      (mark) => _firstOf([
        mark.subLocality,
        mark.locality,
        mark.subAdministrativeArea,
      ]),
    );
    final name = _first(_placeName);
    return PinnedPlace(
      location: point,
      name: name == area ? '' : name,
      area: area,
      block: _first(_block),
      street: _streetName(streetMark?.thoroughfare ?? '', area),
      building: streetMark?.subThoroughfare ?? '',
    );
  }

  String _first(String Function(PlacemarkModel mark) read) {
    for (final mark in this) {
      final value = read(mark);
      if (value.isNotEmpty) return value;
    }
    return '';
  }
}

/// "Block 5", "Blk. 5", "قطعة 5" → `5`.
final RegExp _blockPattern = RegExp(
  r'(?:\bblock|\bblk\.?|قطعة)\s*(\d+)',
  caseSensitive: false,
);

/// An Open Location Code ("8RJF+H3"): what a geocoder names a point that has
/// no address — a code, not a name for a person to read.
final RegExp _plusCodePattern = RegExp(
  r'^[23456789CFGHJMPQRVWX]{2,8}\+[23456789CFGHJMPQRVWX]{0,3}$',
  caseSensitive: false,
);

final RegExp _digitsOnly = RegExp(r'^\d+$');

/// What Google's geocoder calls a road it has no name for, in the app's
/// languages: not a street a courier can look for.
const Set<String> _unnamedRoads = {'unnamed road', 'طريق بدون اسم'};

bool _isUnnamedRoad(String text) => _unnamedRoads.contains(text.toLowerCase());

bool _isStreet(String text) => text.isNotEmpty && !_isUnnamedRoad(text);

String _block(PlacemarkModel mark) {
  for (final text in [
    mark.name,
    mark.street,
    mark.subLocality,
    mark.thoroughfare,
  ]) {
    final match = _blockPattern.firstMatch(text);
    if (match != null) return match.group(1)!;
  }
  return '';
}

/// A name worth showing: not a plus code, not a bare number, not a road
/// with no name, not the street, block, district, governorate or country
/// printed again.
String _placeName(PlacemarkModel mark) {
  final name = mark.name;
  final bare =
      name.isEmpty ||
      _plusCodePattern.hasMatch(name) ||
      _digitsOnly.hasMatch(name) ||
      _blockPattern.hasMatch(name) ||
      _isUnnamedRoad(name) ||
      name == mark.thoroughfare ||
      name == mark.street ||
      name == mark.subThoroughfare ||
      name == mark.subLocality ||
      name == mark.locality ||
      name == mark.subAdministrativeArea ||
      name == mark.administrativeArea ||
      name == mark.country;
  return bare ? '' : name;
}

/// The street, unless the geocoder only repeated the area's name.
String _streetName(String street, String area) => street == area ? '' : street;

String _firstOf(List<String> values) {
  for (final value in values) {
    if (value.isNotEmpty) return value;
  }
  return '';
}
