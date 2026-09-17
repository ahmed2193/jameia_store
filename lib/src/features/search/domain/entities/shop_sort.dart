/// Sort modes for the shop/dish results page chip bar — mirrors Jameia's
/// `common_filter_bar` sort tabs. The label is resolved in the presentation
/// layer via `'search.${sort.labelKey}'.tr()` so the domain stays i18n-free.
enum ShopSort {
  recommended('sort_recommended'),
  rating('sort_rating'),
  deliveryTime('sort_delivery_time'),
  distance('sort_distance');

  const ShopSort(this.labelKey);

  /// Trailing segment of the `search.*` i18n key for this sort's chip label.
  final String labelKey;
}
