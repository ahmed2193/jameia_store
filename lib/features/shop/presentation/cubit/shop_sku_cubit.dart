import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';

/// Business logic for the multi-SKU product-detail sheet.
///
/// Extracted from `_ProductSkuSheetState` in `product_sku_sheet.dart`. Owns the
/// selected variant index, the quantity, and the derived (VIP/Mart-aware) price
/// / availability math; orchestrates add-to-cart by delegating to [CartCubit].
///
/// The [Product] (+ owning `shopId`) is supplied at construction. The active
/// VIP flag is passed in as [isVip] (read from the global `StoreModeCubit` at
/// the call site) instead of reaching into `core/data/keeta_repository.dart`, so
/// the derived price reflects the active store mode selected when the sheet
/// opened.
///
/// TODO(P2.9-boundary): [product] stays the core `Product` DTO — `showProductSku`
/// is called cross-feature (product-details PDP) with the core model, and the
/// chosen variant is pushed into the cart feature (also core `Product`).
class ShopSkuCubit extends Cubit<ShopSkuState>
    with SafeCubitMixin<ShopSkuState> {
  ShopSkuCubit({
    required this.product,
    required this.shopId,
    required bool isVip,
  })  : _isVip = isVip,
        super(_initial(product, isVip));

  final Product product;
  final String shopId;
  final bool _isVip;

  static ShopSkuState _initial(Product product, bool isVip) {
    // Default to the first in-stock variant (else the first) — mirrors
    // `_ProductSkuSheetState.initState`.
    var index = product.variants.indexWhere((e) => e.inStock);
    if (index < 0) index = 0;
    return _build(product, isVip, index, 1);
  }

  /// Recompute the derived state from the product + current selection.
  static ShopSkuState _build(
    Product product,
    bool isVip,
    int variantIndex,
    int quantity,
  ) {
    final vip = isVip;
    final ProductVariant? variant =
        product.hasVariants ? product.variants[variantIndex] : null;
    // Variant price wins when a SKU is chosen (mirrors `_unitPrice`).
    final unitPrice = variant?.price ?? product.priceFor(vip);
    final oldPrice = variant?.oldPrice ?? product.originalPrice;
    final image = (variant?.image.isNotEmpty ?? false)
        ? variant!.image
        : product.image;
    // Out-of-stock guard: product available AND (if SKUs) the chosen one in
    // stock (mirrors `_canAdd`).
    final canAdd =
        product.available && (variant == null || variant.inStock);
    return ShopSkuState(
      variantIndex: variantIndex,
      quantity: quantity,
      unitPrice: unitPrice,
      oldPrice: oldPrice,
      image: image,
      canAdd: canAdd,
    );
  }

  /// Select an in-stock variant (callers should not pass an out-of-stock index;
  /// matches the original chip's `onTap == null` gate).
  void selectVariant(int index) {
    if (index < 0 ||
        !product.hasVariants ||
        index >= product.variants.length ||
        index == state.variantIndex) {
      return;
    }
    safeEmit(_build(product, _isVip, index, state.quantity));
  }

  /// Increase quantity by one.
  void increment() => setQuantity(state.quantity + 1);

  /// Decrease quantity by one (floored at 1, mirroring the sheet stepper).
  void decrement() => setQuantity(state.quantity - 1);

  /// Set the quantity (clamped to ≥ 1).
  void setQuantity(int quantity) {
    final q = quantity < 1 ? 1 : quantity;
    if (q == state.quantity) return;
    safeEmit(_build(product, _isVip, state.variantIndex, q));
  }

  /// Add the chosen variant × quantity to the cart, delegating to [CartCubit].
  ///
  /// Behaviour ported verbatim from `_ProductSkuSheetState._addToCart`: adds one
  /// line per unit and passes `unitPrice: product.priceFor(vip)` (the product's
  /// active-mode price, NOT the variant price) so the cart charge matches the
  /// original screen exactly.
  void addToCart(CartCubit cart) {
    if (!state.canAdd) return;
    final vip = _isVip;
    final variant = product.hasVariants
        ? product.variants[state.variantIndex]
        : null;
    cart.add(
      product,
      shopId,
      variant: variant,
      unitPrice: product.priceFor(vip),
      qty: state.quantity,
    );
  }
}

/// Derived sku-sheet state. Equatable so the sheet rebuilds only on real change.
class ShopSkuState extends Equatable {
  const ShopSkuState({
    required this.variantIndex,
    required this.quantity,
    required this.unitPrice,
    required this.oldPrice,
    required this.image,
    required this.canAdd,
  });

  /// Index of the chosen variant (0 when the product has no SKUs).
  final int variantIndex;

  /// Quantity to add (≥ 1).
  final int quantity;

  /// VIP/Mart-aware unit price (variant price wins when a SKU is chosen).
  final double unitPrice;

  /// Struck-through original price (variant `oldPrice`, else product
  /// `originalPrice`). 0 == no discount.
  final double oldPrice;

  /// Header image (chosen variant image, else the product image).
  final String image;

  /// Whether add-to-cart is allowed (available + chosen SKU in stock).
  final bool canAdd;

  @override
  List<Object?> get props =>
      [variantIndex, quantity, unitPrice, oldPrice, image, canAdd];
}
