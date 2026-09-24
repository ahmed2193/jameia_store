import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/datasources/catalog_remote_data_source.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_query.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/end_points.dart';
import 'package:jameia_mart/src/core/network/locale_provider.dart';

import 'network/network_test_fakes.dart';

const Map<String, dynamic> _rice = {
  '_id': '6aa6010d06da786e3f5658f9',
  'name': 'Basmati Rice 5kg',
  'slug': 'basmati-rice-5kg',
  'type': 'standard',
  'price': 3250,
  'compareAt': 4063,
  'stock': 80,
};

/// The language the datasource reads its cache key from.
class _MutableLocale implements LocaleProvider {
  _MutableLocale(this.languageCode);

  @override
  String languageCode;
}

void main() {
  late FakeHttpClientAdapter adapter;
  late _MutableLocale locale;
  late DateTime clock;

  CatalogRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
    adapter = transport;
    locale = _MutableLocale('en');
    clock = DateTime(2026, 9, 20, 12);
    return CatalogRemoteDataSourceImpl(
      DioConsumer(Dio()..httpClientAdapter = adapter),
      locale,
      now: () => clock,
    );
  }

  RequestOptions request() => adapter.requests.single;

  group('getProducts', () {
    test('GETs the query + page + limit and parses the page', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody({
            'data': [_rice],
            'pagination': {'total': 9, 'page': 2, 'limit': 4, 'hasMore': true},
          }),
        ),
      );

      final page = await dataSource.getProducts(
        query: const CatalogProductQuery(
          categorySlug: 'grocery',
          inStockOnly: true,
          sort: CatalogProductSort.priceLowToHigh,
        ),
        page: 2,
        limit: 4,
      );

      expect(request().method, 'GET');
      expect(request().path, EndPoints.products);
      expect(request().queryParameters, {
        'page': 2,
        'limit': 4,
        'categorySlug': 'grocery',
        'inStock': true,
        'sort': 'price_asc',
      });
      expect(page.items.single.slug, 'basmati-rice-5kg');
      expect(page.page, 2);
      expect(page.hasMore, isTrue);
    });

    test('a non-object payload is a ParsingException', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody([_rice])),
      );

      expect(
        () => dataSource.getProducts(
          query: const CatalogProductQuery(),
          page: 1,
          limit: 20,
        ),
        throwsA(isA<ParsingException>()),
      );
    });

    test(
      'a 400 from the backend is a BadRequestException with its code',
      () async {
        final dataSource = build(
          FakeHttpClientAdapter(
            (_, _) => envelope(
              status: 400,
              statusMessage: 'VALIDATION_ERROR',
              errorMessage: 'Validation failed',
            ),
          ),
        );

        expect(
          () => dataSource.getProducts(
            query: const CatalogProductQuery(),
            page: 1,
            limit: 500,
          ),
          throwsA(
            isA<BadRequestException>().having(
              (error) => error.code,
              'code',
              'VALIDATION_ERROR',
            ),
          ),
        );
      },
    );
  });

  group('getCategories', () {
    test('GETs the flat tree and skips a malformed row', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody({
            'data': [
              {'_id': 'c1', 'slug': 'fresh-food', 'name': 'Fresh Food'},
              {'name': 'no identity'},
              {'_id': 'c2', 'slug': 'apples', 'parentId': 'c1'},
            ],
          }),
        ),
      );

      final categories = await dataSource.getCategories();

      expect(request().path, EndPoints.categories);
      expect(request().queryParameters, isEmpty);
      expect([for (final c in categories) c.slug], ['fresh-food', 'apples']);
      expect(categories.last.parentId, 'c1');
    });

    test('reuses the tree; refresh and a language switch ask again', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody({
            'data': [
              {'_id': 'c1', 'slug': 'fresh-food', 'name': 'Fresh Food'},
            ],
          }),
        ),
      );

      await dataSource.getCategories();
      await dataSource.getCategories();
      expect(adapter.requests, hasLength(1));

      await dataSource.getCategories(refresh: true);
      expect(adapter.requests, hasLength(2));

      // Category names arrive resolved by `Accept-Language`.
      locale.languageCode = 'ar';
      await dataSource.getCategories();
      expect(adapter.requests, hasLength(3));

      // …and the tree goes stale on its own.
      clock = clock.add(
        CatalogRemoteDataSourceImpl.categoryTreeTtl +
            const Duration(seconds: 1),
      );
      await dataSource.getCategories();
      expect(adapter.requests, hasLength(4));
    });
  });

  group('getBrands', () {
    test('GETs page + limit, adds a non-blank search', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody({
            'data': [
              {'_id': 'b1', 'slug': 'almarai', 'name': 'Almarai'},
            ],
            'pagination': {
              'total': 1,
              'page': 1,
              'limit': 50,
              'hasMore': false,
            },
          }),
        ),
      );

      final brands = await dataSource.getBrands(
        page: 1,
        limit: 50,
        search: ' alm ',
      );

      expect(request().path, EndPoints.brands);
      expect(request().queryParameters, {
        'page': 1,
        'limit': 50,
        'search': 'alm',
      });
      expect(brands.single.slug, 'almarai');
    });

    test('a blank search is not sent', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody({'data': <Object>[]})),
      );

      await dataSource.getBrands(page: 1, limit: 20, search: '  ');

      expect(request().queryParameters, {'page': 1, 'limit': 20});
    });
  });
}
