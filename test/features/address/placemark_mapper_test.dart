// Reading a Kuwait address out of the device geocoder's answers for a pin:
// the district, block, street and number, a place's name — and nothing
// invented (no plus code as a name, no number on another street).
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/features/address/data/mappers/placemark_mapper.dart';
import 'package:hero_mart/src/features/address/data/models/placemark_model.dart';
import 'package:hero_mart/src/features/address/domain/entities/pinned_place.dart';

void main() {
  const pin = GeoPointEntity(lat: 29.334, lng: 48.078);

  test('no answer: just the point', () {
    expect(
      const <PlacemarkModel>[].toPinnedPlace(pin),
      const PinnedPlace.at(pin),
    );
  });

  test('district, block, street and its number from the answers', () {
    const marks = [
      PlacemarkModel(
        name: '14',
        street: 'Salem Al Mubarak St, 14',
        thoroughfare: 'Salem Al Mubarak St',
        subThoroughfare: '14',
        subLocality: 'Salmiya',
        locality: 'Kuwait City',
      ),
      PlacemarkModel(name: 'Block 10', subLocality: 'Salmiya'),
    ];

    final place = marks.toPinnedPlace(pin);

    expect(place.location, pin);
    expect(place.area, 'Salmiya');
    expect(place.block, '10');
    expect(place.street, 'Salem Al Mubarak St');
    expect(place.building, '14');
    expect(place.name, isEmpty); // "14" is the number, not a name
  });

  test('Arabic block words are read too', () {
    const marks = [PlacemarkModel(name: 'قطعة 4', subLocality: 'الجابرية')];
    final place = marks.toPinnedPlace(pin);
    expect(place.block, '4');
    expect(place.area, 'الجابرية');
  });

  test('a plus code is never a name; a real place is', () {
    expect(
      const [PlacemarkModel(name: '8RJF+H3', locality: 'Salmiya')]
          .toPinnedPlace(pin)
          .name,
      isEmpty,
    );
    expect(
      const [
        PlacemarkModel(name: 'Marina Mall', thoroughfare: 'Arabian Gulf St'),
      ].toPinnedPlace(pin).name,
      'Marina Mall',
    );
  });

  test('a number stays with its own street', () {
    const marks = [
      PlacemarkModel(subThoroughfare: '7', subLocality: 'Hawally'),
      PlacemarkModel(thoroughfare: 'Tunis St', subLocality: 'Hawally'),
    ];
    final place = marks.toPinnedPlace(pin);
    expect(place.street, 'Tunis St');
    expect(place.building, isEmpty);
  });

  test('a road with no name is no street and no name, in either language', () {
    for (final unnamed in ['Unnamed Road', 'طريق بدون اسم', 'unnamed road']) {
      final place = [
        PlacemarkModel(
          name: unnamed,
          thoroughfare: unnamed,
          subLocality: 'Jahra',
        ),
        const PlacemarkModel(thoroughfare: 'Street 5', subLocality: 'Jahra'),
      ].toPinnedPlace(pin);
      expect(place.street, 'Street 5', reason: unnamed);
      expect(place.name, isEmpty, reason: unnamed);
      expect(place.area, 'Jahra', reason: unnamed);
    }
  });

  test('a governorate or the country is no place name: a spot in the '
      'desert reads as nothing', () {
    // The Android geocoder's answers for a spot in the Jahra desert.
    final place = [
      PlacemarkModel.fromGeocoder(
        name: 'طريق بدون اسم',
        street: 'طريق بدون اسم، الكويت\u200E',
        thoroughfare: 'طريق بدون اسم',
        administrativeArea: 'الجهراء',
        country: 'الكويت\u200E',
      ),
      PlacemarkModel.fromGeocoder(
        name: 'الجهراء',
        street: 'الجهراء، الكويت\u200E',
        administrativeArea: 'الجهراء',
        country: 'الكويت\u200E',
      ),
      PlacemarkModel.fromGeocoder(
        name: 'الكويت\u200E',
        street: 'الكويت\u200E',
        country: 'الكويت\u200E',
      ),
    ].toPinnedPlace(pin);
    expect(place.isBare, isTrue);
  });

  test('a name that only repeats the district is no place name', () {
    final place = const [
      PlacemarkModel(name: 'Salmiya', thoroughfare: 'Street 1'),
      PlacemarkModel(locality: 'Salmiya'),
    ].toPinnedPlace(pin);
    expect(place.area, 'Salmiya');
    expect(place.name, isEmpty);
  });

  test("the geocoder's strings are cleaned: trimmed, without direction "
      'marks, a missing one empty', () {
    final mark = PlacemarkModel.fromGeocoder(
      name: ' Marina Mall\u200F ',
      country: 'الكويت\u200E',
    );
    expect(mark.name, 'Marina Mall');
    expect(mark.country, 'الكويت');
    expect(mark.locality, isEmpty);
  });

  test('a street that only repeats the district is dropped', () {
    const marks = [
      PlacemarkModel(thoroughfare: 'Salmiya', subLocality: 'Salmiya'),
    ];
    expect(marks.toPinnedPlace(pin).street, isEmpty);
  });
}
