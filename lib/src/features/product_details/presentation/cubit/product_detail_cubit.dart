import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../../../core/utils/performance/snapshot_loader_mixin.dart';
import '../../domain/entities/product_detail.dart';
import '../../domain/usecases/get_product_offer_usecase.dart';
import '../../domain/usecases/watch_product_detail_usecase.dart';
import 'product_detail_state.dart';

/// The product page: loads `GET /v1/products/:slug` — the copy saved on the
/// device first (offline too), then the server's — and keeps the customer's
/// selection (variant, quantity, gallery page). Once the product is in, the
/// cart offer that counts it is looked up for the offer tag under the
/// product's name. Adding to the cart is the page's job (`CartCubit` is
/// app-global); this cubit says what may be added.
class ProductDetailCubit extends Cubit<ProductDetailState>
    with
        SafeCubitMixin<ProductDetailState>,
        SnapshotLoaderMixin<ProductDetailState>,
        ScreenLoaderMixin<ProductDetailState> {
  ProductDetailCubit(
    this._watchDetail,
    this._getProductOffer, {
    required this._slug,
    CatalogProductEntity? preview,
  }) : super(ProductDetailState(preview: preview));

  final WatchProductDetailUseCase _watchDetail;
  final GetProductOfferUseCase _getProductOffer;
  final String _slug;

  /// Bumped by every read; the promo of an older one is stale.
  int _generation = 0;

  /// First load, retry, language switch. A reload keeps the page on screen and
  /// the customer's selection when it still exists.
  Future<void> load() {
    showLoading();
    return _read(forceRefresh: false);
  }

  /// The server's page (the reconnect refresh of a saved or failed one; a
  /// product that does not exist stays "not found").
  @override
  Future<void> refresh() => _read(forceRefresh: true);

  Future<void> _read({required bool forceRefresh}) async {
    final generation = ++_generation;
    await readScreen<ProductDetail>(
      _watchDetail(WatchProductDetailParams(_slug, forceRefresh: forceRefresh)),
      show: _show,
    );
    final detail = state.detail;
    if (detail != null && generation == _generation && !isClosed) {
      await _loadPromo(detail, generation);
    }
  }

  /// The customer's selection survives when it still exists.
  static ProductDetailState _show(
    ProductDetailState state,
    DataSnapshot<ProductDetail> snapshot,
  ) {
    final detail = snapshot.data;
    final kept = detail.variantById(state.selectedVariantId);
    final variant = (kept != null && kept.isAvailable)
        ? kept
        : detail.defaultVariant;
    final stock = detail.stockOf(variant);
    return state.copyWith(
      detail: detail,
      selectedVariantId: variant?.id,
      quantity: _bounded(state.quantity, stock),
      imageIndex: state.imageIndex < detail.gallery.length
          ? state.imageIndex
          : 0,
    );
  }

  /// The offer tag is extra: a failure leaves the page without one.
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
