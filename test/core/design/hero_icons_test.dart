// The generated HeroIcons font constants (tool/icons/build.js --dart):
// two-tone accent lookup, accent fills, directional glyphs, aliases.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';

/// Every glyph that flips in RTL (dir=y in tool/icons/concepts.tsv).
const List<IconData> _directional = <IconData>[
  HeroIcons.back,
  HeroIcons.arrowForward,
  HeroIcons.arrowUpStart,
  HeroIcons.arrowUpEnd,
  HeroIcons.chevronEnd,
  HeroIcons.chevronStart,
  HeroIcons.help,
  HeroIcons.deliveryDirectional,
  HeroIcons.trendingUp,
  HeroIcons.logout,
];

void main() {
  test('every constant is in the HeroIcons family declared in pubspec', () {
    expect(HeroIcons.fontFamily, 'HeroIcons');
    expect(HeroIcons.bag.fontFamily, HeroIcons.fontFamily);
    expect(HeroIcons.bagAccent.fontFamily, HeroIcons.fontFamily);
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- family: HeroIcons'),
    );
  });

  group('accentOf', () {
    test('returns the accent layer of a two-tone icon', () {
      expect(HeroIcons.accentOf(HeroIcons.bag), HeroIcons.bagAccent);
      expect(HeroIcons.accentOf(HeroIcons.points), HeroIcons.pointsAccent);
      expect(HeroIcons.accentOf(HeroIcons.crown), HeroIcons.crownAccent);
      expect(HeroIcons.accentOf(HeroIcons.cash), HeroIcons.cashAccent);
      expect(HeroIcons.accentOf(HeroIcons.medal), HeroIcons.medalAccent);
    });

    test('is null for an icon without an accent', () {
      expect(HeroIcons.accentOf(HeroIcons.close), isNull);
      expect(HeroIcons.accentOf(HeroIcons.chevronEnd), isNull);
      expect(HeroIcons.accentOf(HeroIcons.pointsFill), isNull);
      expect(HeroIcons.accentOf(HeroIcons.cartAdd), isNull);
      expect(HeroIcons.accentOf(HeroIcons.bagAccent), isNull);
    });

    test('is null for a glyph of another font on the same codepoint', () {
      // Codepoints are stable (tool/icons/codepoints.json): 0xE024 is the bag.
      const material = IconData(0xE024, fontFamily: 'MaterialIcons');
      expect(HeroIcons.bag.codePoint, material.codePoint);
      expect(HeroIcons.accentOf(material), isNull);
    });

    test('an alias resolves through its codepoint unless its direction '
        'differs from the layer', () {
      expect(HeroIcons.accentOf(HeroIcons.account), HeroIcons.personAccent);
      // The van flips in RTL, the delivery layer would not: no layer.
      expect(HeroIcons.accentOf(HeroIcons.deliveryDirectional), isNull);
    });
  });

  group('fillOf', () {
    test('names the natural fill of a two-tone icon', () {
      expect(HeroIcons.fillOf(HeroIcons.bag), HeroIconFill.green);
      expect(HeroIcons.fillOf(HeroIcons.star), HeroIconFill.amber);
      expect(HeroIcons.fillOf(HeroIcons.bell), HeroIconFill.yellow);
      expect(HeroIcons.fillOf(HeroIcons.heart), HeroIconFill.red);
      expect(HeroIcons.fillOf(HeroIcons.search), HeroIconFill.sky);
      expect(HeroIcons.fillOf(HeroIcons.account), HeroIconFill.mint);
    });

    test('covers every icon with an accent layer and nothing else', () {
      final aliases = (jsonDecode(
        File('tool/icons/aliases.json').readAsStringSync(),
      ) as Map<String, dynamic>).cast<String, String>();
      // concepts.tsv: name, dir, draw, replaces, fill.
      final fills = <String, String>{
        for (final row
            in File('tool/icons/concepts.tsv')
                .readAsLinesSync()
                .skip(1)
                .map((line) => line.split('\t'))
                .where((cells) => cells.length > 4 && cells[4].isNotEmpty))
          row.first: row[4],
      };
      final accentSources = Directory('tool/icons/src')
          .listSync()
          .map((file) => file.uri.pathSegments.last)
          .where((name) => name.endsWith('.accent.svg'))
          .map((name) => name.substring(0, name.length - '.accent.svg'.length))
          .toSet();
      expect(fills.keys.toSet(), accentSources);
      var withFill = 0;
      for (final MapEntry(key: name, value: icon) in HeroIcons.byName.entries) {
        final fill = HeroIcons.fillOf(icon);
        final hasAccent = HeroIcons.accentOf(icon) != null;
        expect(fill != null, hasAccent, reason: name);
        // An alias takes its target's fill, unless its layer is dropped.
        expect(fill?.name, hasAccent ? fills[aliases[name] ?? name] : null);
        if (fill != null && !aliases.containsKey(name)) withFill++;
      }
      expect(withFill, accentSources.length);
    });

    test('is null where accentOf is null', () {
      expect(HeroIcons.fillOf(HeroIcons.close), isNull);
      expect(HeroIcons.fillOf(HeroIcons.deliveryDirectional), isNull);
      expect(
        HeroIcons.fillOf(const IconData(0xE024, fontFamily: 'MaterialIcons')),
        isNull,
      );
    });
  });

  test('directional glyphs match the text direction, the rest do not', () {
    final names = (jsonDecode(
      File('tool/icons/directional.json').readAsStringSync(),
    ) as List<dynamic>).cast<String>();
    expect(names, hasLength(_directional.length));
    for (final icon in _directional) {
      expect(icon.matchTextDirection, isTrue, reason: '$icon');
    }
    for (final icon in const <IconData>[
      HeroIcons.delivery,
      HeroIcons.close,
      HeroIcons.search,
      HeroIcons.bag,
      HeroIcons.bagAccent,
    ]) {
      expect(icon.matchTextDirection, isFalse, reason: '$icon');
    }
  });

  test('alias deliveryDirectional shares the delivery glyph and flips', () {
    expect(
      HeroIcons.deliveryDirectional.codePoint,
      HeroIcons.delivery.codePoint,
    );
    expect(HeroIcons.deliveryDirectional.matchTextDirection, isTrue);
    expect(HeroIcons.delivery.matchTextDirection, isFalse);
    expect(HeroIcons.account.codePoint, HeroIcons.person.codePoint);
  });
}
