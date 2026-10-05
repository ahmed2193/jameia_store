// A district found by name however it is typed, in either language.
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/features/address/data/datasources/known_areas_local_data_source.dart';
import 'package:hero_mart/src/features/address/data/mappers/known_area_mapper.dart';
import 'package:hero_mart/src/features/address/domain/entities/known_area.dart';

void main() {
  const sabahAlSalem = KnownArea(
    id: 'sabah-al-salem',
    nameEn: 'Sabah Al-Salem',
    nameAr: 'صباح السالم',
    location: GeoPointEntity(lat: 29.257, lng: 48.057),
    governorateEn: 'Mubarak Al-Kabeer Governorate',
    governorateAr: 'محافظة مبارك الكبير',
  );

  test('its governorate in the language asked', () {
    expect(sabahAlSalem.governorateFor('en'), 'Mubarak Al-Kabeer Governorate');
    expect(sabahAlSalem.governorateFor('ar'), 'محافظة مبارك الكبير');
  });

  test('found while its article is being typed', () {
    for (final typed in [
      'sabah a',
      'sabah al',
      'sabah als',
      'sabah alsa',
      'صباح ا',
      'صباح ال',
      'صباح الس',
    ]) {
      expect(sabahAlSalem.matches(typed), isTrue, reason: typed);
    }
    expect(sabahAlSalem.matches('sabah x'), isFalse);
  });

  test('every district the app knows names its governorate in both '
      'languages, one of the six', () {
    final areas = const KnownAreasLocalDataSourceImpl().areas().toEntities();
    final governorates = {for (final area in areas) area.governorateEn};
    expect(governorates, hasLength(6));
    for (final area in areas) {
      expect(area.governorateEn, endsWith(' Governorate'), reason: area.id);
      expect(area.governorateAr, startsWith('محافظة '), reason: area.id);
    }
    final salmiya = areas.firstWhere((area) => area.id == 'salmiya');
    expect(salmiya.governorateFor('en'), 'Hawalli Governorate');
  });

  test('matches the name however it is written, in both languages', () {
    for (final typed in [
      'sabah',
      'sabah al salem',
      'Sabah Al-Salem',
      'SABAH ALSALEM',
      'صباح',
      'صباح السالم',
      'سالم',
    ]) {
      expect(sabahAlSalem.matches(typed), isTrue, reason: typed);
    }
    expect(sabahAlSalem.matches('jabriya'), isFalse);
    expect(sabahAlSalem.matches('  '), isFalse);
  });

  test('named in full only by the whole name', () {
    expect(sabahAlSalem.isNamedBy('sabah al salem'), isTrue);
    expect(sabahAlSalem.isNamedBy('صباح السالم'), isTrue);
    expect(sabahAlSalem.isNamedBy('sabah'), isFalse);
    expect(sabahAlSalem.isNamedBy(''), isFalse);
  });

  test('its name in the language asked for', () {
    expect(sabahAlSalem.nameFor('ar'), 'صباح السالم');
    expect(sabahAlSalem.nameFor('en'), 'Sabah Al-Salem');
  });

  test('sorts A to Z by its name with the article set aside', () {
    const adan = KnownArea(
      id: 'adan',
      nameEn: 'Adan',
      nameAr: 'العدان',
      location: GeoPointEntity(lat: 29.23, lng: 48.07),
    );
    const sharq = KnownArea(
      id: 'sharq',
      nameEn: 'Sharq',
      nameAr: 'شرق',
      location: GeoPointEntity(lat: 29.38, lng: 47.99),
    );
    // "العدان" sits among the ع's, after "شرق" — not among the ا's.
    expect(adan.sortKeyFor('ar').compareTo(sharq.sortKeyFor('ar')), 1);
    expect(adan.sortKeyFor('en').compareTo(sharq.sortKeyFor('en')), -1);
  });
}
