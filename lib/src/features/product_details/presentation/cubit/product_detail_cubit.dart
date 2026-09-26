import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/product_detail.dart';
import '../../domain/usecases/get_product_detail_usecase.dart';
import '../../domain/usecases/get_product_offer_usecase.dart';
import 'product_detail_state.dart';

/// The product page: loads `GET /v1/products/:slug` and keeps the customer's
/// selection (variant, quantity, gallery page). Once the product is in, the
/// cart offer that counts it is looked up for the buy bar's promo tag. Adding to the cart is the
/// page's job (`CartCubit` is app-global); this cubit says what may be added.
class ProductDetailCubit extends Cubit<ProductDetailState>
    with SafeCubitMixin<ProductDetailState> {
  ProductDetailCubit(
    this._getProductDetail,
    this._getProductOffer, {
    required this._slug,
    CatalogProductEntity? preview,
  }) : super(ProductDetailState(preview: preview));

  final GetProductDetailUseCase _getProductDetail;
  final GetProductOfferUseCase _getProductOffer;
  final String _slug;
  int _generation = 0;

  /// First load, retry, language switch. A reload keeps the page on screen and
  /// the customer's selection when it still exists.
  Future<void> load() async {
    final generation = ++_generation;
    if (!state.isLoaded) {
      safeEmit(state.copyWith(status: ProductDetailStatus.loading));
    }
    final result = await _getProductDetail(GetProductDetailParams(_slug));
    if (generation != _generation) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.isLoaded
              ? ProductDetailStatus.loaded
              : ProductDetailStatus.error,
          failure: failure,
        ),
      ),
      (detail) {
        final kept = detail.variantById(state.selectedVariantId);
        final variant = (kept != null && kept.isAvailable)
            ? kept
            : detail.defaultVariant;
        final stock = detail.stockOf(variant);
        safeEmit(
          state.copyWith(
            status: ProductDetailStatus.loaded,
            detail: detail,
            selectedVariantId: variant?.id,
            quantity: _bounded(state.quantity, stock),
            imageIndex: state.imageIndex < detail.gallery.length
                ? state.imageIndex
                : 0,
          ),
        );
      },
    );
    final detail = state.detail;
    if (detail != null && generation == _generation) {
      await _loadPromo(detail, generation);
    }
  }

  /// The promo tag is extra: a failure leaves the bar without one.
  Future<void> _loadPromo(ProductDetail detail, int generation) async {
    final result = await _getProductOffer(
      GetProductOfferParams(
        productId: detail.product.id,
        categoryIds: detail.offerCategoryIds,
      ),
    );
    if (generation != _generation) return;
    final promo = result.fold((_) => null, (offer) => offer);
    if (promo != null && promo != state.promo) {
      safeEmit(state.copyWith(promo: promo));
    }
  }

  /// Ignores an option that cannot be bought. A new option restarts the
  /// quantity: its stock differs.
  void selectVariant(String variantId) {
    final variant = state.detail?.variantById(variantId);
    if (variant == null ||
        !variant.isAvailable ||
        variantId == state.selectedVariantId) {
      return;
    }
    safeEmit(
      state.copyWith(
        selectedVariantId: variantId,
        quantity: ProductDetailState.minQuantity,
      ),
    );
  }

  void increment() => _setQuantity(state.quantity + 1);

  void decrement() => _setQuantity(state.quantity - 1);

  void _setQuantity(int quantity) {
    final bounded = _bounded(quantity, state.maxQuantity);
    if (bounded != state.quantity) safeEmit(state.copyWith(quantity: bounded));
  }

  void setImageIndex(int index) {
    if (index != state.imageIndex) safeEmit(state.copyWith(imageIndex: index));
  }

  static int _bounded(int quantity, int stock) {
    const min = ProductDetailState.minQuantity;
    final max = stock < min ? min : stock;
    return quantity.clamp(min, max);
  }
}
