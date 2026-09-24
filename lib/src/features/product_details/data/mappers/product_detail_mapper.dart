import '../../../../core/data/mappers/catalog_product_mapper.dart';
import '../../../../core/data/mappers/catalog_taxonomy_mapper.dart';
import '../../../../core/domain/entities/catalog_variant_entity.dart';
import '../../domain/entities/product_detail.dart';
import '../../domain/entities/product_reviews.dart';
import '../models/product_detail_model.dart';
import '../models/product_reviews_model.dart';

/// [ProductDetailModel] (wire) → [ProductDetail].
extension ProductDetailMapper on ProductDetailModel {
  ProductDetail toEntity() => ProductDetail(
    product: product.toEntity(),
    description: description,
    galleryUrls: galleryUrls,
    brand: brand?.toEntity(),
    category: category?.toEntity(),
    variants: [for (final variant in variants) variant.toEntity()],
    bundleItems: [
      for (final item in bundleItems)
        ProductBundleItem(
          product: item.product.toEntity(),
          quantity: item.quantity,
          unitPriceFils: item.unitPrice,
        ),
    ],
    related: related.toEntities(),
    recipes: recipes.toEntities(),
  );
}

extension ProductDetailVariantMapper on ProductVariantModel {
  CatalogVariantEntity toEntity() => CatalogVariantEntity(
    id: id,
    name: name,
    priceFils: price,
    proPriceFils: proPrice,
    compareAtFils: compareAt,
    compareAtExpiresAt: compareAtExpiresAt,
    stock: stock,
    enabled: enabled,
  );
}

/// [ProductReviewsModel] (wire) → [ProductReviews].
extension ProductReviewsMapper on ProductReviewsModel {
  static const int _minRating = 1;
  static const int _maxRating = 5;

  ProductReviews toEntity() => ProductReviews(
    reviews: [
      for (final item in items)
        ProductReview(
          id: item.id,
          rating: item.rating.clamp(_minRating, _maxRating),
          createdAt: item.createdAt,
          title: item.title,
          body: item.body,
          customerName: item.customerName,
        ),
    ],
    page: page,
    hasMore: hasMore,
    total: total,
    ratingAverage: ratingAverage,
    ratingCount: ratingCount,
  );
}
