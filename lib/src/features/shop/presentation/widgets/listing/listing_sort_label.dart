import '../../../../../core/domain/entities/catalog_product_query.dart';

/// i18n key of a product ordering (`null` = the backend's default order).
abstract final class ListingSortLabel {
  static const List<CatalogProductSort?> options = <CatalogProductSort?>[
    null,
    CatalogProductSort.newest,
    CatalogProductSort.priceLowToHigh,
    CatalogProductSort.priceHighToLow,
    CatalogProductSort.discount,
    CatalogProductSort.name,
  ];

  static String keyOf(CatalogProductSort? sort) => switch (sort) {
    null => 'shop.sort_recommended',
    CatalogProductSort.newest => 'shop.sort_newest',
    CatalogProductSort.priceLowToHigh => 'shop.sort_price_asc',
    CatalogProductSort.priceHighToLow => 'shop.sort_price_desc',
    CatalogProductSort.discount => 'shop.sort_discount',
    CatalogProductSort.name => 'shop.sort_name',
  };
}
