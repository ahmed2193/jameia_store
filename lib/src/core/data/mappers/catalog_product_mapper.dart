import '../../domain/entities/catalog_product_entity.dart';
import '../../domain/entities/catalog_products_page.dart';
import '../models/product_model.dart';
import '../models/products_page_model.dart';

/// The catalogue card back to its wire shape, so a pending line survives a
/// restart with its picture and price.
extension CatalogProductModelMapper on CatalogProductEntity {
  ProductModel toModel() => ProductModel(
    id: id,
    slug: slug,
    name: name,
    type: switch (type) {
      CatalogProductType.standard => 'standard',
      CatalogProductType.variant => 'variant',
      CatalogProductType.bundle => 'bundle',
      CatalogProductType.other => ProductModel.standardType,
    },
    price: priceFils,
    proPrice: proPriceFils,
    compareAt: compareAtFils,
    image: image,
    stock: stock,
    tags: tags,
    unitOfSale: switch (unitOfSale) {
      UnitOfSale.piece => 'piece',
      UnitOfSale.kg => 'kg',
      UnitOfSale.litre => 'l',
      UnitOfSale.pack => 'pack',
      UnitOfSale.other => ProductModel.pieceUnit,
    },
    ratingAverage: ratingAverage,
    ratingCount: ratingCount,
  );
}

/// [ProductModel] (wire) → [CatalogProductEntity].
extension CatalogProductMapper on ProductModel {
  /// The backend leaks raw tag ids (24-hex Mongo ids) among the tag slugs.
  static final RegExp _objectId = RegExp(r'^[0-9a-fA-F]{24}$');

  CatalogProductEntity toEntity() => CatalogProductEntity(
    id: id,
    slug: slug,
    name: name,
    type: _typeOf(type),
    priceFils: price,
    proPriceFils: proPrice,
    compareAtFils: compareAt,
    image: image,
    stock: stock,
    tags: [
      for (final tag in tags)
        if (!_objectId.hasMatch(tag)) tag,
    ],
    unitOfSale: _unitOf(unitOfSale),
    ratingAverage: ratingAverage,
    ratingCount: ratingCount,
  );

  static CatalogProductType _typeOf(String wire) => switch (wire) {
    'standard' => CatalogProductType.standard,
    'variant' => CatalogProductType.variant,
    'bundle' => CatalogProductType.bundle,
    _ => CatalogProductType.other,
  };

  static UnitOfSale _unitOf(String wire) => switch (wire) {
    'piece' => UnitOfSale.piece,
    'kg' => UnitOfSale.kg,
    'l' => UnitOfSale.litre,
    'pack' => UnitOfSale.pack,
    _ => UnitOfSale.other,
  };
}

extension CatalogProductListMapper on List<ProductModel> {
  List<CatalogProductEntity> toEntities() =>
      map((model) => model.toEntity()).toList(growable: false);
}

/// [ProductsPageModel] (wire) → [CatalogProductsPage].
extension CatalogProductsPageMapper on ProductsPageModel {
  CatalogProductsPage toEntity() => CatalogProductsPage(
    products: items.toEntities(),
    page: page,
    hasMore: hasMore,
    total: total,
  );
}
