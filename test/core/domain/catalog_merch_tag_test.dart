// The merchandising tags a catalogue product wears: only the ones the app
// can name, most telling first whatever order the backend sends them in —
// the listing pill wears the first, the product page shows them all.
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_merch_tag.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';

CatalogProductEntity _tagged(List<String> tags) =>
    CatalogProductEntity(id: 'p1', slug: 'p1', name: 'Milk', tags: tags);

void main() {
  group('CatalogProductEntity.merchTags', () {
    test('most telling first, whatever the wire order', () {
      expect(_tagged(['fresh', 'best-seller']).merchTags, [
        CatalogMerchTag.bestSeller,
        CatalogMerchTag.fresh,
      ]);
      expect(_tagged(['fresh']).merchTags, [CatalogMerchTag.fresh]);
    });

    test('a tag slug the app does not know is not one', () {
      expect(_tagged(['organic']).merchTags, isEmpty);
      expect(_tagged(const []).merchTags, isEmpty);
    });
  });

  group('CatalogProductEntity.leadMerchTag', () {
    test('is the first of merchTags', () {
      expect(
        _tagged(['fresh', 'best-seller']).leadMerchTag,
        CatalogMerchTag.bestSeller,
      );
      expect(_tagged(['organic', 'fresh']).leadMerchTag, CatalogMerchTag.fresh);
    });

    test('is null without a tag the app knows', () {
      expect(_tagged(['organic']).leadMerchTag, isNull);
      expect(_tagged(const []).leadMerchTag, isNull);
    });
  });

  test('every tag has its wire slug and a label', () {
    expect(CatalogMerchTag.bestSeller.slug, 'best-seller');
    expect(CatalogMerchTag.fresh.slug, 'fresh');
    expect(CatalogMerchTag.bestSeller.labelKey, 'shop.tag_best_seller');
    expect(CatalogMerchTag.fresh.labelKey, 'shop.tag_fresh');
  });
}
