import 'package:equatable/equatable.dart';

/// One selectable SKU of a product — e.g. size S / M / L with its own price,
/// stock and gallery image. Drives the multi-SKU product sheet.
class ProductVariantEntity extends Equatable {
  const ProductVariantEntity({
    required this.sku,
    required this.label,
    required this.price,
    this.oldPrice = 0,
    this.image = '',
    this.inStock = true,
  });

  final String sku;

  /// Option display name (e.g. "M").
  final String label;
  final double price;

  /// 0 == no discount.
  final double oldPrice;
  final String image;
  final bool inStock;

  bool get hasDiscount => oldPrice > price && oldPrice > 0;

  @override
  List<Object?> get props => [sku, label, price, oldPrice, image, inStock];
}
