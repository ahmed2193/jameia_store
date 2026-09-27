/// A merchandising tag of the backend catalogue that a customer can read, in
/// the order a page shows them: the most telling first. A product's `tags[]`
/// carries these slugs beside raw tag ids, which the mapper drops.
enum CatalogMerchTag {
  bestSeller('best-seller', 'shop.tag_best_seller'),
  fresh('fresh', 'shop.tag_fresh');

  const CatalogMerchTag(this.slug, this.labelKey);

  /// The wire value in `tags[]`.
  final String slug;

  /// The i18n key of its label (the listing pill and the product page's
  /// chips say the same).
  final String labelKey;
}
