import 'package:equatable/equatable.dart';

import 'product_entity.dart';
import 'shop_entity.dart';

/// Loaded snapshot for the Jameia `fixed_price` flash channel — the host flash
/// [ShopEntity] plus its hot-selling products (discounted lines first, so the
/// grid leads with the deals). Built by [GetFixedPriceUseCase].
class FixedPriceView extends Equatable {
  const FixedPriceView({required this.shop, required this.products});

  /// The single promo storefront backing the fixed-price channel.
  final ShopEntity shop;

  /// Hot-selling products, sorted by discount percent (highest first).
  final List<ProductEntity> products;

  @override
  List<Object?> get props => [shop, products];
}
