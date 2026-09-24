import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/mappers/catalog_product_mapper.dart';
import 'package:jameia_mart/src/core/data/mappers/catalog_product_query_mapper.dart';
import 'package:jameia_mart/src/core/data/mappers/catalog_taxonomy_mapper.dart';
import 'package:jameia_mart/src/core/data/models/category_model.dart';
import 'package:jameia_mart/src/core/data/models/product_model.dart';
import 'package:jameia_mart/src/core/data/models/products_page_model.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_products_page.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_variant_entity.dart';

CatalogProductEntity _product(String id, {int price = 1000}) =>
    CatalogProductEntity(id: id, slug: id, name: id, priceFils: price);

void main() {
  group('CatalogProductMapper', () {
    test('maps the wire product, enums and drops leaked tag ids', () {
      const model = ProductModel(
        id: '6aa6010d06da786e3f5658f4',
        slug: 'fresh-eggs-30',
        name: 'Fresh Eggs (30)',
        type: 'standard',
        price: 2250,
        compareAt: 2813,
        image: 'https://x/eggs.png',
        stock: 60,
        tags: ['6aa5ffb85233feadc5c41502', 'fresh', 'best-seller'],
        unitOfSale: 'pack',
        ratingAverage: 4,
        ratingCount: 2,
      );

      final entity = model.toEntity();

      expect(entity.id, '6aa6010d06da786e3f5658f4');
      expect(entity.slug, 'fresh-eggs-30');
      expect(entity.type, CatalogProductType.standard);
      expect(entity.unitOfSale, UnitOfSale.pack);
      expect(entity.priceFils, 2250);
      expect(entity.compareAtFils, 2813);
      expect(entity.tags, ['fresh', 'best-seller']);
      expect(entity.ratingCount, 2);
    });

    test('unknown wire enums map to other, litre is "l" on the wire', () {
      expect(
        const ProductModel(
          id: 'a',
          slug: 'a',
          type: 'subscription',
        ).toEntity().type,
        CatalogProductType.other,
      );
      expect(
        const ProductModel(
          id: 'a',
          slug: 'a',
          unitOfSale: 'l',
        ).toEntity().unitOfSale,
        UnitOfSale.litre,
      );
      expect(
        const ProductModel(
          id: 'a',
          slug: 'a',
          unitOfSale: 'dozen',
        ).toEntity().unitOfSale,
        UnitOfSale.other,
      );
    });

    test('page mapping keeps the pagination', () {
      const page = ProductsPageModel(
        items: [ProductModel(id: 'a', slug: 'a')],
        total: 9,
        page: 2,
        limit: 4,
        hasMore: true,
      );

      final entity = page.toEntity();

      expect(entity.products.single.id, 'a');
      expect(entity.page, 2);
      expect(entity.total, 9);
      expect(entity.hasMore, isTrue);
    });
  });

  group('CatalogProductEntity', () {
    test('discount maths in fils', () {
      const rice = CatalogProductEntity(
        id: 'r',
        slug: 'r',
        name: 'Rice',
        priceFils: 3250,
        compareAtFils: 4063,
        stock: 80,
      );

      expect(rice.hasDiscount, isTrue);
      expect(rice.discountPercent, 20);
      expect(rice.priceKd, 3.25);
      expect(rice.compareAtKd, 4.063);
      expect(rice.canQuickAdd, isTrue);
    });

    test('a variant product has no list price, discount or quick add', () {
      const milk = CatalogProductEntity(
        id: 'm',
        slug: 'm',
        name: 'Milk',
        type: CatalogProductType.variant,
        priceFils: 0,
        compareAtFils: 100,
        stock: 32,
      );

      expect(milk.hasListPrice, isFalse);
      expect(milk.hasDiscount, isFalse);
      expect(milk.discountPercent, 0);
      expect(milk.compareAtKd, 0);
      expect(milk.canQuickAdd, isFalse);
    });

    test('pro price applies only to a pro member and only when lower', () {
      const withPro = CatalogProductEntity(
        id: 'p',
        slug: 'p',
        name: 'P',
        priceFils: 1000,
        proPriceFils: 900,
      );
      const bogusPro = CatalogProductEntity(
        id: 'p',
        slug: 'p',
        name: 'P',
        priceFils: 1000,
        proPriceFils: 1200,
      );

      expect(withPro.priceFilsFor(pro: true), 900);
      expect(withPro.priceFilsFor(pro: false), 1000);
      expect(bogusPro.hasProPrice, isFalse);
      expect(bogusPro.priceFilsFor(pro: true), 1000);
    });

    test('out of stock cannot be quick-added', () {
      expect(_product('x').canQuickAdd, isFalse);
    });
  });

  group('CatalogVariantEntity', () {
    final now = DateTime.utc(2026, 9, 17);

    test('struck price expires', () {
      final variant = CatalogVariantEntity(
        id: 'v1',
        name: '1 L',
        priceFils: 499,
        compareAtFils: 550,
        compareAtExpiresAt: DateTime.utc(2026, 9, 16),
        stock: 18,
      );

      expect(variant.compareAtFilsAt(now), isNull);
      expect(variant.discountPercentAt(now), 0);
      expect(variant.compareAtFilsAt(DateTime.utc(2026, 9, 15)), 550);
    });

    test('availability needs enabled and stock', () {
      const disabled = CatalogVariantEntity(
        id: 'v',
        name: 'v',
        stock: 5,
        enabled: false,
      );
      const empty = CatalogVariantEntity(id: 'v', name: 'v');

      expect(disabled.isAvailable, isFalse);
      expect(empty.isAvailable, isFalse);
    });
  });

  group('CatalogProductsPage.merge', () {
    test('appends a later page and drops products already shown', () {
      final first = CatalogProductsPage(
        products: [_product('a'), _product('b')],
        page: 1,
        hasMore: true,
        total: 3,
      );
      final second = CatalogProductsPage(
        products: [_product('b'), _product('c')],
        page: 2,
        hasMore: false,
        total: 3,
      );

      final merged = first.merge(second);

      expect([for (final p in merged.products) p.id], ['a', 'b', 'c']);
      expect(merged.page, 2);
      expect(merged.hasMore, isFalse);
    });
  });

  group('CatalogCategoryTree', () {
    const models = [
      CategoryModel(id: 'apples', slug: 'apples', parentId: 'fruits'),
      CategoryModel(id: 'dairy', slug: 'dairy-eggs', sortOrder: 1),
      CategoryModel(id: 'fresh', slug: 'fresh-food'),
      CategoryModel(id: 'meat', slug: 'meat', parentId: 'fresh', sortOrder: 1),
      CategoryModel(id: 'fruits', slug: 'fruits', parentId: 'fresh'),
      CategoryModel(
        id: 'orphan',
        slug: 'orphan',
        parentId: 'missing',
        sortOrder: 9,
      ),
    ];

    test('rebuilds roots and children in backend order', () {
      final tree = models.toTree();

      expect(
        [for (final c in tree.roots) c.slug],
        ['fresh-food', 'dairy-eggs', 'orphan'],
      );
      expect(
        [for (final c in tree.childrenOf('fresh')) c.slug],
        ['fruits', 'meat'],
      );
      expect(tree.childrenOf('apples'), isEmpty);
      expect(tree.bySlug('apples')?.parentId, 'fruits');
      expect(tree.bySlug('nope'), isNull);
    });

    test('empty tree', () {
      expect(CatalogCategoryTree.empty.isEmpty, isTrue);
      expect(CatalogCategoryTree.empty.roots, isEmpty);
    });
  });

  group('CatalogProductQueryMapper', () {
    test('sends only what the query sets', () {
      const query = CatalogProductQuery(categorySlug: 'fresh-food');

      expect(query.toQueryParameters(page: 1, limit: 20), {
        'page': 1,
        'limit': 20,
        'categorySlug': 'fresh-food',
      });
    });

    test('maps every filter and the sort wire values', () {
      const query = CatalogProductQuery(
        search: '  rice ',
        brandSlug: 'nestle',
        collectionSlug: 'todays-deals',
        tag: 'best-seller',
        inStockOnly: true,
        onSaleOnly: true,
        minPriceFils: 1000,
        maxPriceFils: 3000,
        sort: CatalogProductSort.discount,
      );

      expect(query.toQueryParameters(page: 2, limit: 50), {
        'page': 2,
        'limit': 50,
        'search': 'rice',
        'brandSlug': 'nestle',
        'collectionSlug': 'todays-deals',
        'tag': 'best-seller',
        'inStock': true,
        'onSale': true,
        'minPrice': 1000,
        'maxPrice': 3000,
        'sort': 'discount_desc',
      });
    });

    test('never sends inStock=false, a blank search or a blank slug', () {
      const query = CatalogProductQuery(search: '   ', categorySlug: ' ');

      expect(query.toQueryParameters(page: 1, limit: 20), {
        'page': 1,
        'limit': 20,
      });
    });

    test('cuts an over-long search to the backend limit', () {
      final query = CatalogProductQuery(search: 'x' * 200);

      expect(
        (query.toQueryParameters(page: 1, limit: 20)['search'] as String)
            .length,
        CatalogProductQuery.maxTextLength,
      );
    });

    test('sort wire values', () {
      String? wire(CatalogProductSort sort) =>
          CatalogProductQuery(sort: sort)
                  .toQueryParameters(page: 1, limit: 1)['sort']
              as String?;

      expect(wire(CatalogProductSort.newest), 'newest');
      expect(wire(CatalogProductSort.priceLowToHigh), 'price_asc');
      expect(wire(CatalogProductSort.priceHighToLow), 'price_desc');
      expect(wire(CatalogProductSort.name), 'name');
    });
  });
}
