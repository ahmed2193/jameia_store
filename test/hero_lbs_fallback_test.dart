// Smoke test: HeroLbs offline fallback.
//
// In the test VM the native geocoder MethodChannel and the Google Places HTTP
// endpoints are unavailable, so HeroLbs must degrade gracefully to the
// deterministic offline data instead of throwing. Verifies reverse() resolves
// with fromNetwork==false and a non-empty city/area, and nearby() yields at
// least one candidate.

import 'package:flutter_test/flutter_test.dart';

import 'package:hero_mart/src/core/utils/hero_geocode.dart';
import 'package:hero_mart/src/core/utils/lbs_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const base = HeroGeocode.base;

  test('reverse(base) falls back offline (fromNetwork == false)', () async {
    final r = await HeroLbs.reverse(base);
    expect(r.fromNetwork, isFalse);
    expect(r.city, isNotEmpty);
    expect(r.area, isNotEmpty);
    expect(r.line, isNotEmpty);
  });

  test('nearby(base) returns at least 1 candidate without throwing', () async {
    final list = await HeroLbs.nearby(base);
    expect(list, isNotEmpty);
    expect(list.first.title, isNotEmpty);
    expect(list.first.pos.latitude, base.latitude);
    expect(list.first.pos.longitude, base.longitude);
  });
}
