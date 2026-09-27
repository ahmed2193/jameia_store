import 'package:hero_mart/src/core/data/datasources/catalog_remote_data_source.dart';
import 'package:hero_mart/src/core/data/models/brand_model.dart';
import 'package:hero_mart/src/core/data/models/category_model.dart';
import 'package:hero_mart/src/core/data/models/offer_model.dart';
import 'package:hero_mart/src/core/data/models/products_page_model.dart';
import 'package:hero_mart/src/core/data/models/remote_payload.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_query.dart';

/// A [CatalogRemoteDataSource] for tests: a `get…` read throws
/// [UnimplementedError] until the test overrides it, and a `fetch…` read
/// answers with its `get…` twin plus an empty raw payload — a test of the
/// device copy overrides the `fetch…` read with real `results` instead.
abstract class FakeCatalogRemoteDataSource implements CatalogRemoteDataSource {
  static const Map<String, Object?> _noRaw = <String, Object?>{};

  @override
  Future<ProductsPageModel> getProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) => throw UnimplementedError();

  @override
  Future<RemotePayload<ProductsPageModel>> fetchProducts({
    required CatalogProductQuery query,
    required int page,
    required int limit,
  }) async => RemotePayload(
    await getProducts(query: query, page: page, limit: limit),
    _noRaw,
  );

  @override
  Future<List<CategoryModel>> getCategories({bool refresh = false}) =>
      throw UnimplementedError();

  @override
  Future<RemotePayload<List<CategoryModel>>> fetchCategories() async =>
      RemotePayload(await getCategories(refresh: true), _noRaw);

  @override
  Future<List<BrandModel>> getBrands({
    required int page,
    required int limit,
    String? search,
  }) => throw UnimplementedError();

  @override
  Future<RemotePayload<List<BrandModel>>> fetchBrands({
    required int page,
    required int limit,
    String? search,
  }) async => RemotePayload(
    await getBrands(page: page, limit: limit, search: search),
    _noRaw,
  );

  @override
  Future<List<OfferModel>> getOffers() => throw UnimplementedError();

  @override
  Future<RemotePayload<List<OfferModel>>> fetchOffers() async =>
      RemotePayload(await getOffers(), _noRaw);
}
