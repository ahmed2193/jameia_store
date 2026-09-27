import '../../domain/entities/catalog_product_query.dart';
import '../../network/api_consumer.dart';
import '../../network/api_payload.dart';
import '../../network/end_points.dart';
import '../../network/locale_provider.dart';
import '../mappers/catalog_product_query_mapper.dart';
import '../models/brand_model.dart';
import '../models/catalog_results.dart';
import '../models/category_model.dart';
import '../models/offer_model.dart';
import '../models/products_page_model.dart';
import '../models/remote_payload.dart';

/// The catalogue reads more than one feature needs — the product list (shop,
/// search, discovery, product page, the cart's deals sheet), the category tree
/// (home, shop, search, the deals sheet), the brand list (search, discovery)
/// and the cart offers (the product page's promo tag). One shared datasource instead of a copy
/// per feature; a route only one feature reads (home feed, product detail,
/// collections, recipes …) stays in that feature.
///
/// Each `fetch…` read also hands back the raw `results`, for a screen that
/// keeps its copy on the device (`CatalogCacheDataSource`); the `get…` ones
/// are the same reads for the callers that need the models only.
///
/// Public routes (Bearer optional). Receives the envelope's `results`
/// (unwrapped by `DioConsumer`); throws `AppException` only.
abstract class CatalogRemoteDataSource {
  /// `GET /v1/products?page&limit&search&categorySlug&brandSlug&collectionSlug&tag&inStock&onSale&minPrice&maxPrice&sort`.
  /// [limit] is capped by the backend at 100.
  Future<ProductsPageModel> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  });

  /// [getProducts], with the raw `results`.
  Future<RemotePayload<ProductsPageModel>> fetchProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  });

  /// `GET /v1/categories` — the whole tree, flat, not paginated. The last
  /// answer is kept for a short while (see
  /// [CatalogRemoteDataSourceImpl.categoryTreeTtl]); [refresh] skips it.
  Future<List<CategoryModel>> getCategories({bool refresh = false});

  /// `GET /v1/categories` from the network, with the raw `results`; the
  /// tree [getCategories] keeps is replaced by it.
  Future<RemotePayload<List<CategoryModel>>> fetchCategories();

  /// `GET /v1/brands?page&limit&search`.
  Future<List<BrandModel>> getBrands({
    required int page,
    required int limit,
    String? search,
  });

  /// [getBrands], with the raw `results`.
  Future<RemotePayload<List<BrandModel>>> fetchBrands({
    required int page,
    required int limit,
    String? search,
  });

  /// `GET /v1/offers?page=1&limit=100` — the store's cart promotions (one
  /// page is the whole list in practice). Kept like the category tree for
  /// [CatalogRemoteDataSourceImpl.categoryTreeTtl]: every product page reads
  /// it for its promo tag.
  Future<List<OfferModel>> getOffers();

  /// `GET /v1/offers` from the network, with the raw `results`; the list
  /// [getOffers] keeps is replaced by it.
  Future<RemotePayload<List<OfferModel>>> fetchOffers();
}

class CatalogRemoteDataSourceImpl implements CatalogRemoteDataSource {
  CatalogRemoteDataSourceImpl(
    this._api,
    this._locale, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ApiConsumer _api;
  final LocaleProvider _locale;

  /// Injectable so the cache window is testable.
  final DateTime Function() _now;

  static const String pageField = 'page';
  static const String limitField = 'limit';
  static const String searchField = 'search';
  static const int maxOffers = 100;

  /// How long the category tree is reused. Browsing reads it on every screen
  /// (the store tab, a category page, search discover) while it is one small
  /// page that changes about as often as the store's shelves; without this
  /// every tap on a category would re-download the whole tree.
  static const Duration categoryTreeTtl = Duration(minutes: 5);

  List<CategoryModel>? _categories;

  /// The language the cached tree was read in — the backend resolves category
  /// names by `Accept-Language`, so a switch must not reuse it.
  String? _categoriesLanguage;
  DateTime? _categoriesReadAt;

  List<OfferModel>? _offers;

  /// Offer names are resolved by `Accept-Language` too.
  String? _offersLanguage;
  DateTime? _offersReadAt;

  /// The offers read in flight and the language it asked in: a second
  /// reader (the checkout and its "Coupons & offers" page open together)
  /// shares it instead of sending the same request again.
  Future<RemotePayload<List<OfferModel>>>? _offersInFlight;
  String? _offersInFlightLanguage;

  @override
  Future<ProductsPageModel> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) async =>
      (await fetchProducts(query: query, page: page, limit: limit)).model;

  @override
  Future<RemotePayload<ProductsPageModel>> fetchProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) async {
    final results = ApiPayload.asMap(
      await _api.get(
        EndPoints.products,
        queryParameters: query.toQueryParameters(page: page, limit: limit),
      ),
      EndPoints.products,
    );
    return RemotePayload(CatalogResults.products(results, page: page), results);
  }

  @override
  Future<List<CategoryModel>> getCategories({bool refresh = false}) async {
    final cached = _categories;
    final readAt = _categoriesReadAt;
    if (!refresh &&
        cached != null &&
        _categoriesLanguage == _locale.languageCode &&
        readAt != null &&
        _now().difference(readAt) < categoryTreeTtl) {
      return cached;
    }
    return (await fetchCategories()).model;
  }

  @override
  Future<RemotePayload<List<CategoryModel>>> fetchCategories() async {
    final language = _locale.languageCode;
    final results = ApiPayload.asMap(
      await _api.get(EndPoints.categories),
      EndPoints.categories,
    );
    final rows = CatalogResults.categories(results);
    _categories = rows;
    _categoriesLanguage = language;
    _categoriesReadAt = _now();
    return RemotePayload(rows, results);
  }

  @override
  Future<List<BrandModel>> getBrands({
    required int page,
    required int limit,
    String? search,
  }) async =>
      (await fetchBrands(page: page, limit: limit, search: search)).model;

  @override
  Future<RemotePayload<List<BrandModel>>> fetchBrands({
    required int page,
    required int limit,
    String? search,
  }) async {
    final text = search?.trim() ?? '';
    final results = ApiPayload.asMap(
      await _api.get(
        EndPoints.brands,
        queryParameters: <String, dynamic>{
          pageField: page,
          limitField: limit,
          if (text.isNotEmpty) searchField: text,
        },
      ),
      EndPoints.brands,
    );
    return RemotePayload(CatalogResults.brands(results), results);
  }

  @override
  Future<List<OfferModel>> getOffers() async {
    final cached = _offers;
    final readAt = _offersReadAt;
    if (cached != null &&
        _offersLanguage == _locale.languageCode &&
        readAt != null &&
        _now().difference(readAt) < categoryTreeTtl) {
      return cached;
    }
    return (await fetchOffers()).model;
  }

  @override
  Future<RemotePayload<List<OfferModel>>> fetchOffers() async {
    final language = _locale.languageCode;
    final inFlight = _offersInFlight;
    if (inFlight != null && _offersInFlightLanguage == language) {
      return inFlight;
    }
    final read = _readOffers(language);
    _offersInFlight = read;
    _offersInFlightLanguage = language;
    try {
      return await read;
    } finally {
      if (identical(_offersInFlight, read)) _offersInFlight = null;
    }
  }

  Future<RemotePayload<List<OfferModel>>> _readOffers(String language) async {
    final results = ApiPayload.asMap(
      await _api.get(
        EndPoints.offers,
        queryParameters: <String, dynamic>{pageField: 1, limitField: maxOffers},
      ),
      EndPoints.offers,
    );
    final rows = CatalogResults.offers(results);
    _offers = rows;
    _offersLanguage = language;
    _offersReadAt = _now();
    return RemotePayload(rows, results);
  }
}
