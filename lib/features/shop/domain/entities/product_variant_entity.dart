import 'package:equatable/equatable.dart';

/// Framework-free product-variant (SKU) entity.
///
/// Owned by the shop feature (no reuse of the core `ProductVariant` DTO). One
/// selectable SKU of a [ProductEntity] — e.g. size S / M / L with its own price,
/// stock and gallery image. Plain Dart + equatable only.
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
