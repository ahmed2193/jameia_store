import '../../domain/entities/catalog_product_query.dart';
import '../../network/api_consumer.dart';
import '../../network/api_payload.dart';
import '../../network/end_points.dart';
import '../../network/locale_provider.dart';
import '../mappers/catalog_product_query_mapper.dart';
import '../models/brand_model.dart';
import '../models/category_model.dart';
import '../models/json_read.dart';
import '../models/products_page_model.dart';

/// The catalogue reads more than one feature needs — the product list (shop,
/// search, discovery, product page), the category tree (home, shop, search) and
/// the brand list (search, discovery). One shared datasource instead of a copy
/// per feature; a route only one feature reads (home feed, product detail,
/// collections, recipes …) stays in that feature.
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

  /// `GET /v1/categories` — the whole tree, flat, not paginated. The last
  /// answer is kept for a short while (see
  /// [CatalogRemoteDataSourceImpl.categoryTreeTtl]); [refresh] skips it.
  Future<List<CategoryModel>> getCategories({bool refresh = false});

  /// `GET /v1/brands?page&limit&search`.
  Future<List<BrandModel>> getBrands({
    required int page,
    required int limit,
    String? search,
  });
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

  static const String dataKey = 'data';
  static const String pageField = 'page';
  static const String limitField = 'limit';
  static const String searchField = 'search';
  static const String _logName = 'CatalogRemoteDataSource';

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

  @override
  Future<ProductsPageModel> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) async {
    final results = await _api.get(
      EndPoints.products,
      queryParameters: query.toQueryParameters(page: page, limit: limit),
    );
    return ProductsPageModel.fromJson(
      ApiPayload.asMap(results, EndPoints.products),
      requestedPage: page,
    );
  }

  @override
  Future<List<CategoryModel>> getCategories({bool refresh = false}) async {
    final language = _locale.languageCode;
    final cached = _categories;
    final readAt = _categoriesReadAt;
    if (!refresh &&
        cached != null &&
        _categoriesLanguage == language &&
        readAt != null &&
        _now().difference(readAt) < categoryTreeTtl) {
      return cached;
    }
    final results = await _api.get(EndPoints.categories);
    final payload = ApiPayload.asMap(results, EndPoints.categories);
    final rows = JsonRead.rows(
      payload[dataKey],
      CategoryModel.fromJson,
      logName: _logName,
    );
    _categories = rows;
    _categoriesLanguage = language;
    _categoriesReadAt = _now();
    return rows;
  }

  @override
  Future<List<BrandModel>> getBrands({
    required int page,
    required int limit,
    String? search,
  }) async {
    final text = search?.trim() ?? '';
    final results = await _api.get(
      EndPoints.brands,
      queryParameters: <String, dynamic>{
        pageField: page,
        limitField: limit,
        if (text.isNotEmpty) searchField: text,
      },
    );
    final payload = ApiPayload.asMap(results, EndPoints.brands);
    return JsonRead.rows(
      payload[dataKey],
      BrandModel.fromJson,
      logName: _logName,
    );
  }
}
