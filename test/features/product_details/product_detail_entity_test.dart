// The pure rules the product page's widgets ask the entity: how the related
// products split into "Shop more for less" (on a deal) and "Similar
// products" (the rest), each in the backend's order, and the buy bar's
// struck total.
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_variant_entity.dart';
import 'package:jameia_mart/src/features/product_details/domain/entities/product_detail.dart';

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
        detail.struckTotalKd(variant: null, pro: false, now: now, quantity: 2),
        1.25,
      );
    });

    test('a Pro member paying less: the regular price struck', () {
      final detail = ProductDetail(
        product: _product('milk', proPriceFils: 450),
      );

      expect(
        detail.struckTotalKd(variant: null, pro: true, now: now, quantity: 3),
        1.5,
      );
      expect(
        detail.struckTotalKd(variant: null, pro: false, now: now, quantity: 3),
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
        detail.struckTotalKd(variant: pack, pro: false, now: now, quantity: 1),
        2.2,
      );
      expect(
        detail.struckTotalKd(
          variant: pack,
          pro: false,
          now: DateTime(2026, 11),
          quantity: 1,
        ),
        isNull,
      );
    });

    test('no deal, no Pro price: nothing struck', () {
      final detail = ProductDetail(product: _product('milk'));

      expect(
        detail.struckTotalKd(variant: null, pro: true, now: now, quantity: 1),
        isNull,
      );
    });
  });
}
