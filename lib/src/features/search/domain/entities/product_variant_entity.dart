import 'package:equatable/equatable.dart';

/// Framework-free counterpart of the core `ProductVariant` DTO — one selectable
/// SKU (size / option) of a [ProductEntity]. Plain Dart + equatable only; carried
/// so a search-rail product can be reconstructed losslessly for the cross-feature
/// product-detail push (see `presentation/util/product_boundary.dart`).
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
  final String label;
  final double price;
  final double oldPrice; // 0 == no discount
  final String image;
  final bool inStock;

  bool get hasDiscount => oldPrice > price && oldPrice > 0;

  @override
  List<Object?> get props => [sku, label, price, oldPrice, image, inStock];
}
