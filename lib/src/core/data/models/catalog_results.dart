import '../../network/api_payload.dart';
import '../../network/end_points.dart';
import 'brand_model.dart';
import 'category_model.dart';
import 'json_read.dart';
import 'offer_model.dart';
import 'products_page_model.dart';

/// The envelope `results` of the shared catalogue routes, parsed — ONE parser
/// per route, used for a reply (`CatalogRemoteDataSource`) and for the copy
/// saved on the device (`CatalogCacheDataSource`) alike. A malformed row is
/// logged and skipped; a payload that is not an object is a
/// `ParsingException`.
abstract final class CatalogResults {
  static const String dataKey = 'data';
  static const String _logName = 'catalog';

  /// `GET /v1/categories` — `{ data: [...] }`, the whole tree, flat.
  static List<CategoryModel> categories(Object? results) => JsonRead.rows(
    ApiPayload.asMap(results, EndPoints.categories)[dataKey],
    CategoryModel.fromJson,
    logName: _logName,
  );

  /// `GET /v1/brands` — `{ data: [...], pagination }`.
  static List<BrandModel> brands(Object? results) => JsonRead.rows(
    ApiPayload.asMap(results, EndPoints.brands)[dataKey],
    BrandModel.fromJson,
    logName: _logName,
  );

  /// `GET /v1/offers` — `{ data: [...], pagination }`.
  static List<OfferModel> offers(Object? results) => JsonRead.rows(
    ApiPayload.asMap(results, EndPoints.offers)[dataKey],
    OfferModel.fromJson,
    logName: _logName,
  );

  /// `GET /v1/products` — one page; [page] when the reply does not say.
  static ProductsPageModel products(Object? results, {required int page}) =>
      ProductsPageModel.fromJson(
        ApiPayload.asMap(results, EndPoints.products),
        requestedPage: page,
      );
}
