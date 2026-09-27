// The shared catalogue's device copies: public (cached before the session is
// known and kept for every customer), per language, parsed back with the
// same CatalogResults parsers as a reply; one entry per normalised listing
// query; an unparseable copy throws for the cache policy to drop it.
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/datasources/cache_slots.dart';
import 'package:jameia_mart/src/core/data/datasources/catalog_cache_data_source.dart';
import 'package:jameia_mart/src/core/data/models/brand_model.dart';
import 'package:jameia_mart/src/core/data/models/catalog_results.dart';
import 'package:jameia_mart/src/core/data/models/category_model.dart';
import 'package:jameia_mart/src/core/data/models/offer_model.dart';
import 'package:jameia_mart/src/core/data/models/product_model.dart';
import 'package:jameia_mart/src/core/data/models/products_page_model.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/storage/cache_owner.dart';

import '../network/network_test_fakes.dart';
import '../storage/cache_test_fakes.dart';

void main() {
  late InMemoryJsonCacheStore store;
  late FakeLocaleProvider locale;
  late CatalogCacheDataSourceImpl cache;
  final savedAt = DateTime.utc(2026, 9, 27, 12);

  setUp(() {
    store = InMemoryJsonCacheStore();
    locale = FakeLocaleProvider('en');
    cache = CatalogCacheDataSourceImpl(
      CacheSlots(store: store, owner: CacheOwner(), locale: locale),
    );
  });

  test('every catalogue slot is public: there before the session is', () {
    expect(cache.categories(), isNotNull);
    expect(cache.brands(limit: 100), isNotNull);
    expect(cache.offers(), isNotNull);
    expect(cache.products(const CatalogProductQuery(), limit: 20), isNotNull);
  });

  test('a saved reply parses back with the reply parsers', () async {
    const categories = {
      CatalogResults.dataKey: [
        {CategoryModel.idKey: 'c1', CategoryModel.slugKey: 'dairy'},
        'not a row',
      ],
    };
    const brands = {
      CatalogResults.dataKey: [
        {BrandModel.idKey: 'b1', BrandModel.slugKey: 'kdd'},
      ],
    };
    const offers = {
      CatalogResults.dataKey: [
        {OfferModel.idKey: 'o1', OfferModel.nameKey: 'Free delivery'},
      ],
    };
    const products = {
      ProductsPageModel.dataKey: [
        {ProductModel.idKey: 'p1', ProductModel.slugKey: 'rice'},
      ],
    };
    final slot = cache.categories()!;
    await slot.write(categories, savedAt: savedAt);

    final saved = await slot.read();

    expect(saved!.savedAt, savedAt);
    expect(slot.parse(saved.data).single.slug, 'dairy');
    expect(cache.brands(limit: 100)!.parse(brands).single.slug, 'kdd');
    expect(cache.offers()!.parse(offers).single.id, 'o1');
    expect(
      cache
          .products(const CatalogProductQuery(), limit: 20)!
          .parse(products)
          .items
          .single
          .slug,
      'rice',
    );
  });

  test('a copy that no longer parses throws for the policy to drop', () {
    expect(
      () => cache
          .products(const CatalogProductQuery(), limit: 20)!
          .parse(const <String, Object?>{}),
      throwsA(isA<ParsingException>()),
    );
    expect(
      () => cache.categories()!.parse('not an object'),
      throwsA(isA<ParsingException>()),
    );
  });

  test('each language keeps its own copy', () async {
    await cache.categories()!.write(const {
      CatalogResults.dataKey: <Object>[],
    }, savedAt: savedAt);

    locale.languageCode = 'ar';

    expect(await cache.categories()!.read(), isNull);
  });

  group('queryId', () {
    String id(CatalogProductQuery query, {int limit = 20}) =>
        CatalogCacheDataSourceImpl.queryId(query, limit: limit);

    test('the request as sent, sorted: equal requests share an entry', () {
      expect(
        id(const CatalogProductQuery(categorySlug: 'dairy', onSaleOnly: true)),
        'categorySlug=dairy&limit=20&onSale=true&page=1',
      );
      expect(
        id(const CatalogProductQuery(search: '  ')),
        id(const CatalogProductQuery()),
        reason: 'a blank search sends nothing',
      );
    });

    test('another filter, sort or page size is another entry', () {
      const dairy = CatalogProductQuery(categorySlug: 'dairy');

      expect(id(dairy), isNot(id(const CatalogProductQuery())));
      expect(
        id(dairy),
        isNot(
          id(
            const CatalogProductQuery(
              categorySlug: 'dairy',
              sort: CatalogProductSort.priceLowToHigh,
            ),
          ),
        ),
      );
      expect(id(dairy), isNot(id(dairy, limit: 40)));
    });
  });
}
