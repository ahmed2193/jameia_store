// Shared domain helpers + the core DTO ⇄ entity mapper the offline catalogue
// still feeds (the coupon wallet).
//
// Verifies:
// - the pure `pickLocalized(languageCode, en:, ar:)` rule;
// - the coupon mapper keeps the DTO fields, and `titleFor` / `subtitleFor`
//   pick exactly what the DTO `display*` getters pick under
//   `Intl.defaultLocale` (en / ar).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:hero_mart/src/core/data/mappers/mappers.dart';
import 'package:hero_mart/src/core/data/models/models.dart';
import 'package:hero_mart/src/core/domain/entities/entities.dart';

/// Runs [body] with `Intl.defaultLocale` set to [locale] (the source the DTO
/// `display*` getters read), restoring the previous value afterwards.
T _withLocale<T>(String locale, T Function() body) {
  final previous = Intl.defaultLocale;
  Intl.defaultLocale = locale;
  try {
    return body();
  } finally {
    Intl.defaultLocale = previous;
  }
}

const _languages = ['en', 'ar'];

void main() {
  late Map<String, dynamic> heroData;

  setUpAll(() {
    heroData = json.decode(
      File('assets/data/hero_data.json').readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  List<Map<String, dynamic>> rows(Object? list) =>
      (list as List).cast<Map<String, dynamic>>();

  group('pickLocalized', () {
    test('Arabic wins only for ar* codes with a non-blank Arabic value', () {
      expect(pickLocalized('en', en: 'Milk', ar: 'حليب'), 'Milk');
      expect(pickLocalized('ar', en: 'Milk', ar: 'حليب'), 'حليب');
      expect(pickLocalized('ar_KW', en: 'Milk', ar: 'حليب'), 'حليب');
      expect(pickLocalized('ar', en: 'Milk', ar: ''), 'Milk');
      expect(pickLocalized('ar', en: 'Milk', ar: '   '), 'Milk');
      // English is returned even when empty (same as the DTO rule).
      expect(pickLocalized('en', en: '', ar: 'حليب'), '');
    });
  });

  group('Coupon', () {
    test('coupon fields + titleFor/subtitleFor match the DTO', () {
      final coupons = rows(heroData['coupons']).map(Coupon.fromJson).toList();
      expect(coupons, isNotEmpty);
      for (final c in coupons) {
        final e = c.toEntity();
        expect(e.amount, c.amount);
        expect(e.minSpend, c.minSpend);
        expect(e.used, c.used);
        for (final lang in _languages) {
          _withLocale(lang, () {
            expect(e.titleFor(lang), c.displayTitle, reason: c.id);
            expect(e.subtitleFor(lang), c.displaySubtitle, reason: c.id);
          });
        }
      }
    });
  });
}
