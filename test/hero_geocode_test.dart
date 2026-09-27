// Smoke test: HeroGeocode offline LBS contract.
//
// Pure / static — no network, no platform views. Verifies the deterministic
// reverse geocode, the serviceable-city polygon gate, and the 3-candidate
// nearby list, all from the Kuwait base coordinate.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:hero_mart/src/core/utils/hero_geocode.dart';

void main() {
  const base = HeroGeocode.base;

  test('reverse(base) returns non-empty area + line + plusCode', () {
    final r = HeroGeocode.reverse(base);
    expect(r.area, isNotEmpty);
    expect(r.line, isNotEmpty);
    expect(r.plusCode, isNotEmpty);
  });

  test('isServiceable(base) == true; isServiceable(0,0) == false', () {
    expect(HeroGeocode.isServiceable(base), isTrue);
    expect(HeroGeocode.isServiceable(const LatLng(0, 0)), isFalse);
  });

  test('nearbyCandidates(base) returns 3 entries, each with its own pos', () {
    final c = HeroGeocode.nearbyCandidates(base);
    expect(c.length, 3);

    // First candidate is the exact pin position.
    expect(c.first.pos.latitude, base.latitude);
    expect(c.first.pos.longitude, base.longitude);

    // Each candidate carries a title + subtitle.
    for (final e in c) {
      expect(e.title, isNotEmpty);
      expect(e.subtitle, isNotEmpty);
    }

    // The 3 positions are distinct (the pin visibly slides on selection).
    final positions = c
        .map((e) => '${e.pos.latitude},${e.pos.longitude}')
        .toSet();
    expect(positions.length, 3);
  });
}
