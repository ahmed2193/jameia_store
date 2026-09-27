// The pure rules the product page's widgets ask the entity: how the related
// products split into "Shop more for less" (on a deal) and "Similar
// products" (the rest), each in the backend's order, and the buy bar's
// quote — its struck total, the deal's percent off and the Pro line.
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_variant_entity.dart';
import 'package:hero_mart/src/features/product_details/domain/entities/product_detail.dart';

CatalogProductEntity _product(
  String id, {
  int? compareAtFils,
  int? proPriceFils,
}) => CatalogProductEntity(
  id: id,
  slug: id,
  name: id,
  priceFils: 500,
  compareAtFils: compareAtFils,
  proPriceFils: proPriceFils,
);

void main() {
  group('related products', () {
    final laban = _product('laban');
    final cheese = _product('cheese', compareAtFils: 600);
    final yoghurt = _product('yoghurt');
    final butter = _product('butter', compareAtFils: 700);
    // A struck price that is not above the price is no deal.
    final cream = _product('cream', compareAtFils: 500);

    test('deals and the rest, each in the backend order', () {
      final detail = ProductDetail(
        product: _product('milk'),
        related: [laban, cheese, yoghurt, butter, cream],
      );

      expect(detail.relatedOnDeal, [cheese, butter]);
      expect(detail.relatedRegular, [laban, yoghurt, cream]);
    });

    test('no related products: both empty', () {
      final detail = ProductDetail(product: _product('milk'));

      expect(detail.relatedOnDeal, isEmpty);
      expect(detail.relatedRegular, isEmpty);
    });

    test('all on a deal: nothing is "similar"', () {
      final detail = ProductDetail(
        product: _product('milk'),
        related: [cheese, butter],
      );

      expect(detail.relatedOnDeal, [cheese, butter]);
      expect(detail.relatedRegular, isEmpty);
    });
  });

  group('struck total', () {
    final now = DateTime(2026, 9, 26);

    test('a deal: its price before, times the pieces', () {
      final detail = ProductDetail(
        product: _product('milk', compareAtFils: 625),
      );

      expect(
        detail
            .quoteFor(variant: null, pro: false, now: now, quantity: 2)
            .struckKd,
        1.25,
      );
    });

    test('a Pro member paying less: the regular price struck', () {
      final detail = ProductDetail(
        product: _product('milk', proPriceFils: 450),
      );

      expect(
        detail
            .quoteFor(variant: null, pro: true, now: now, quantity: 3)
            .struckKd,
        1.5,
      );
      expect(
        detail
            .quoteFor(variant: null, pro: false, now: now, quantity: 3)
            .struckKd,
        isNull,
      );
    });

    test('a variant: the chosen option, only while its deal runs', () {
      final pack = CatalogVariantEntity(
        id: 'pack',
        name: '4x',
        priceFils: 2050,
        compareAtFils: 2200,
        compareAtExpiresAt: DateTime(2026, 10),
        stock: 9,
      );
      final detail = ProductDetail(
        product: const CatalogProductEntity(
          id: 'cola',
          slug: 'cola',
          name: 'Cola',
          type: CatalogProductType.variant,
        ),
        variants: [pack],
      );

      expect(
        detail
            .quoteFor(variant: pack, pro: false, now: now, quantity: 1)
            .struckKd,
        2.2,
      );
      expect(
        detail
            .quoteFor(
              variant: pack,
              pro: false,
              now: DateTime(2026, 11),
              quantity: 1,
            )
            .struckKd,
        isNull,
      );
    });

    test('no deal, no Pro price: nothing struck', () {
      final detail = ProductDetail(product: _product('milk'));

      expect(
        detail
            .quoteFor(variant: null, pro: true, now: now, quantity: 1)
            .struckKd,
        isNull,
      );
    });
  });

  group('the buy bar quote', () {
    final now = DateTime(2026, 9, 26);

    test('a deal: the pieces, their price before and the percent off', () {
      final detail = ProductDetail(
        product: _product('milk', compareAtFils: 625),
      );

      final quote = detail.quoteFor(
        variant: null,
        pro: false,
        now: now,
        quantity: 2,
      );
      expect(quote.unitFils, 500);
      expect(quote.amountFils, 1000);
      expect(quote.amountKd, 1.0);
      expect(quote.struckFils, 1250);
      expect(quote.isDeal, isTrue);
      expect(quote.savePercent, 20);
      expect(quote.proHintFils, isNull);
      expect(quote.proApplied, isFalse);
    });

    test('not a member: the Pro price is offered, nothing struck', () {
      final detail = ProductDetail(
        product: _product('milk', proPriceFils: 450),
      );

      final quote = detail.quoteFor(
        variant: null,
        pro: false,
        now: now,
        quantity: 1,
      );
      expect(quote.amountFils, 500);
      expect(quote.proHintFils, 450);
      expect(quote.proHintKd, 0.45);
      expect(quote.proApplied, isFalse);
      expect(quote.struckKd, isNull);
      expect(quote.savePercent, 0);
    });

    test('a member: pays the Pro price, never offered it again', () {
      final detail = ProductDetail(
        product: _product('milk', proPriceFils: 450),
      );

      final quote = detail.quoteFor(
        variant: null,
        pro: true,
        now: now,
        quantity: 1,
      );
      expect(quote.amountFils, 450);
      expect(quote.proApplied, isTrue);
      expect(quote.proHintFils, isNull);
      expect(quote.struckFils, 500);
      expect(quote.isDeal, isFalse);
    });

    test('a variant product before an option is chosen: nothing to price', () {
      const detail = ProductDetail(
        product: CatalogProductEntity(
          id: 'cola',
          slug: 'cola',
          name: 'Cola',
          type: CatalogProductType.variant,
        ),
        variants: [CatalogVariantEntity(id: 'can', name: 'Can')],
      );

      final quote = detail.quoteFor(
        variant: null,
        pro: false,
        now: now,
        quantity: 1,
      );
      expect(quote.hasPrice, isFalse);
      expect(quote.amountKd, 0);
    });
  });
}
