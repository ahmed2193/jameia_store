// The map styles are valid Google Maps JSON and share one palette: a broken
// style string only fails on the device, silently, as the default map.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/widgets/hero_map_style.dart';

void main() {
  List<Map<String, dynamic>> rules(String style) => [
    for (final rule in jsonDecode(style) as List<dynamic>)
      rule as Map<String, dynamic>,
  ];

  Object? styler(List<Map<String, dynamic>> rules, String feature, String key) {
    for (final rule in rules.reversed) {
      if (rule['featureType'] != feature) continue;
      for (final entry in rule['stylers'] as List<dynamic>) {
        final value = (entry as Map<String, dynamic>)[key];
        if (value != null) return value;
      }
    }
    return null;
  }

  test('both styles are JSON lists of rules with stylers', () {
    for (final style in [HeroMapStyle.brand, HeroMapStyle.picker]) {
      final parsed = rules(style);
      expect(parsed, isNotEmpty);
      for (final rule in parsed) {
        expect(rule['stylers'], isA<List<dynamic>>());
      }
    }
  });

  test('the live map hides place icons; the picker keeps landmarks', () {
    final brand = rules(HeroMapStyle.brand);
    final picker = rules(HeroMapStyle.picker);
    expect(styler(brand, 'poi.business', 'visibility'), 'off');
    expect(styler(picker, 'poi.business', 'visibility'), isNull);
  });

  test('one palette: parks and water are the same on both maps', () {
    final brand = rules(HeroMapStyle.brand);
    final picker = rules(HeroMapStyle.picker);
    for (final feature in ['poi.park', 'water', 'road.highway']) {
      expect(
        styler(picker, feature, 'color'),
        styler(brand, feature, 'color'),
        reason: feature,
      );
    }
  });
}
