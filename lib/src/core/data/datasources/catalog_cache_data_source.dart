import '../../domain/entities/catalog_product_query.dart';
import '../../storage/cache_namespace.dart';
import '../mappers/catalog_product_query_mapper.dart';
import '../models/brand_model.dart';
import '../models/catalog_results.dart';
import '../models/category_model.dart';
import '../models/offer_model.dart';
import '../models/products_page_model.dart';
import 'cache_slots.dart';

/// The shared catalogue replies as last shown, beside
/// `CatalogRemoteDataSource`: public (the same for every customer), kept per
/// language, and parsed back with the same [CatalogResults] parsers as a
/// reply. Only first pages are kept.
abstract class CatalogCacheDataSource {
  /// `GET /v1/categories`.
  CacheSlot<List<CategoryModel>>? categories();

  /// `GET /v1/brands`, the first page of [limit].
  CacheSlot<List<BrandModel>>? brands({required int limit});

  /// `GET /v1/products`, the first page of [query] at [limit] per page.
  CacheSlot<ProductsPageModel>? products(
    CatalogProductQuery query, {
    required int limit,
  });

  /// `GET /v1/offers` — the product page, the checkout and the offers page
  /// share this one copy.
  CacheSlot<List<OfferModel>>? offers();
}

class CatalogCacheDataSourceImpl implements CatalogCacheDataSource {
  const CatalogCacheDataSourceImpl(this._slots);

  final CacheSlots _slots;

  static const int _firstPage = 1;

  /// The tree changes about as often as the shelves: fresh as long as the
  /// remote datasource keeps its memory copy.
  static const CacheNamespace categoriesNamespace = CacheNamespace(
    'catalog.categories',
    scope: CacheScope.public,
    freshFor: Duration(minutes: 5),
    maxAge: Duration(days: 7),
  );

  static const CacheNamespace brandsNamespace = CacheNamespace(
    'catalog.brands',
    scope: CacheScope.public,
    freshFor: Duration(seconds: 60),
    maxAge: Duration(days: 7),
  );

  /// One entry per listing query (and language): the oldest go past 40.
  static const CacheNamespace productsNamespace = CacheNamespace(
    'catalog.products',
    scope: CacheScope.public,
    freshFor: Duration(seconds: 60),
    maxAge: Duration(days: 3),
    maxEntries: 40,
  );

  /// Offers are time-boxed: a copy older than a day is never shown.
  static const CacheNamespace offersNamespace = CacheNamespace(
    'catalog.offers',
    scope: CacheScope.public,
    freshFor: Duration(seconds: 60),
    maxAge: Duration(days: 1),
  );

  @override
  CacheSlot<List<CategoryModel>>? categories() =>
      _slots.of(categoriesNamespace, parse: CatalogResults.categories);

  @override
  CacheSlot<List<BrandModel>>? brands({required int limit}) =>
      _slots.of(brandsNamespace, parse: CatalogResults.brands, id: '$limit');

  @override
  CacheSlot<ProductsPageModel>? products(
    CatalogProductQuery query, {
    required int limit,
  }) => _slots.of(
    productsNamespace,
    parse: (raw) => CatalogResults.products(raw, page: _firstPage),
    id: queryId(query, limit: limit),
  );

  @override
  CacheSlot<List<OfferModel>>? offers() =>
      _slots.of(offersNamespace, parse: CatalogResults.offers);

  /// The first page of [query] as one stable string — the request's own
  /// parameters, sorted — so two queries that send the same request share
  /// one entry (a blank search, the same filters set in another order).
  static String queryId(CatalogProductQuery query, {required int limit}) {
    final parameters = query.toQueryParameters(page: _firstPage, limit: limit);
    final keys = parameters.keys.toList()..sort();
    return [for (final key in keys) '$key=${parameters[key]}'].join('&');
  }
}
