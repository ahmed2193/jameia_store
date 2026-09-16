// Validates the slim jameia asset parses into the expected catalogue graph.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/core/data/jameia/jameia_loader.dart';

void main() {
  test('parseJameiaCatalog builds categories/sections/products with VIP price', () {
    final raw = File('assets/data/jameia/jameia_catalog.json').readAsStringSync();
    final cat = parseJameiaCatalog(raw);

    expect(cat.categories.length, greaterThanOrEqualTo(20));
    expect(cat.sections, isNotEmpty);
    expect(cat.productsBySku.length, greaterThan(8000));

    // A category should have sub-categories; some sub has ranks with products.
    final withRanks = cat.categories
        .expand((c) => c.subs)
        .where((s) => s.hasRanks && s.ranks.any((r) => r.products.isNotEmpty));
    expect(withRanks, isNotEmpty, reason: 'expected ranked sub-categories');

    // VIP pricing merged (only stored when it differs from the Mart price).
    final vipCount = cat.productsBySku.values.where((p) => p.hasVipPrice).length;
    expect(vipCount, greaterThan(500), reason: 'differing VIP prices should be merged');

    // Featured sections carry resolved products.
    expect(cat.sections.any((s) => s.products.isNotEmpty), isTrue);

    // Shared product identity: same sku → same instance across the graph.
    final anyRank = cat.categories
        .expand((c) => c.subs)
        .expand((s) => s.ranks)
        .firstWhere((r) => r.products.isNotEmpty);
    final p = anyRank.products.first;
    expect(identical(cat.productsBySku[p.sku], p), isTrue);

    // Sanity: image URLs were re-expanded from the stripped media base.
    expect(p.image.startsWith('http'), isTrue);
    // Confirm decode produced valid JSON root (guards asset corruption).
    expect(() => json.decode(raw), returnsNormally);
  });
}
