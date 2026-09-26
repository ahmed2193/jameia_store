import 'package:dartz/dartz.dart';

import '../../../../core/data/datasources/catalog_remote_data_source.dart';
import '../../../../core/data/mappers/catalog_product_mapper.dart';
import '../../../../core/data/models/category_model.dart';
import '../../../../core/data/repositories/base_repository_mixin.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/catalog_product_query.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/cart_deals_repository.dart';

/// `GET /v1/categories` (cached by the shared datasource) turns an offer's
/// category id into the slug `GET /v1/products` filters by.
class CartDealsRepositoryImpl
    with BaseRepositoryMixin
    implements CartDealsRepository {
  const CartDealsRepositoryImpl(this._catalog);

  final CatalogRemoteDataSource _catalog;

  static const CatalogProductQuery _onSale = CatalogProductQuery(
    inStockOnly: true,
    onSaleOnly: true,
    sort: CatalogProductSort.discount,
  );

  @override
  Future<Either<Failure, List<CatalogProductEntity>>> getDealProducts({
    String? categoryId,
    required int limit,
  }) => execute(() async {
    final slug = categoryId == null
        ? null
        : _slugOf(await _catalog.getCategories(), categoryId);
    final query = slug == null
        ? _onSale
        : CatalogProductQuery(
            categorySlug: slug,
            inStockOnly: true,
            sort: CatalogProductSort.discount,
          );
    final page = await _catalog.getProducts(query: query, page: 1, limit: limit);
    return page.items.toEntities();
  });

  static String? _slugOf(List<CategoryModel> tree, String id) {
    for (final category in tree) {
      if (category.id == id) return category.slug;
    }
    return null;
  }
}
