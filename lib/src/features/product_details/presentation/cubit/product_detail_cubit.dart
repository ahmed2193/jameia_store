import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/catalog_constants.dart' show kJameiaSupplierId;
import '../../../../core/data/models/models.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../store_mode/domain/repositories/store_mode_repository.dart';
import '../../domain/entities/product_detail.dart';
import '../../domain/repositories/product_details_repository.dart';

/// User's answer to the "Are you satisfied?" prompt. UI-only (not persisted).
enum Satisfaction { none, notSatisfied, satisfied }

enum ProductDetailStatus { initial, loading, loaded, error }

/// Business logic for the full-screen product-detail page (KeeMart PDP).
///
/// Loads the seeded [ProductDetail] straight from [ProductDetailsRepository]
/// (the pass-through use case was collapsed), then owns the page's interactive
/// state: image pager + nutrition toggle, variant selection, quantity,
/// satisfaction and the VIP/Mart-aware price math. Built inline with a runtime
/// [Product] (the `ShopSkuCubit` precedent) — NOT an SL entry.
///
/// The active store mode is read from [StoreModeRepository] (a plain value
/// source with no change notification); the screen's
/// `BlocListener<StoreModeCubit>` calls [onVipModeChanged] when the mode flips.
class ProductDetailCubit extends Cubit<ProductDetailState>
    with SafeCubitMixin<ProductDetailState> {
  ProductDetailCubit({
    required this.product,
    required ProductDetailsRepository repository,
    required StoreModeRepository storeMode,
  }) : _repository = repository,
       _storeMode = storeMode,
       super(const ProductDetailState()) {
    load();
  }

  final Product product;
  final ProductDetailsRepository _repository;
  final StoreModeRepository _storeMode;

  ProductDetail? _detail;

  // ── Convenience accessors for the view (valid once loaded) ──────────────────
  ProductDetail get detail => _detail!;
  Product get hero => _detail?.product ?? product;
  List<String> get gallery => _detail?.gallery ?? const [];
  bool get hasNutrition => (_detail?.kcal ?? 0) > 0;
  int get pageCount => gallery.length + (hasNutrition ? 1 : 0);

  Future<void> load() async {
    if (state.status == ProductDetailStatus.initial) {
      safeEmit(state.copyWith(status: ProductDetailStatus.loading));
    }
    final result = await _repository.getDetails(product);
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: ProductDetailStatus.error,
          error: failure.message,
        ),
      ),
      (detail) {
        _detail = detail;
        safeEmit(_loadedState(detail));
      },
    );
  }

  ProductDetailState _loadedState(
    ProductDetail detail, {
    int imageIndex = 0,
    bool showNutrition = false,
    int variantIndex = -1,
    int quantity = 1,
    Satisfaction satisfaction = Satisfaction.none,
  }) {
    final hero = detail.product;
    var vIndex = variantIndex;
    if (vIndex < 0) {
      vIndex = hero.variants.indexWhere((e) => e.inStock);
      if (vIndex < 0) vIndex = 0;
    }
    return _derive(
      detail,
      vIndex,
      quantity,
      imageIndex: imageIndex,
      showNutrition: showNutrition,
      satisfaction: satisfaction,
    );
  }

  /// Recompute the interactive/derived fields from the hero + selection.
  ProductDetailState _derive(
    ProductDetail detail,
    int variantIndex,
    int quantity, {
    required int imageIndex,
    required bool showNutrition,
    required Satisfaction satisfaction,
  }) {
    final hero = detail.product;
    final vip = _storeMode.isVip;
    final ProductVariant? variant = hero.hasVariants
        ? hero.variants[variantIndex]
        : null;
    final unitPrice = variant?.price ?? hero.priceFor(vip);
    final oldPrice = variant?.oldPrice ?? hero.originalPrice;
    final image = (variant?.image.isNotEmpty ?? false)
        ? variant!.image
        : hero.image;
    final discountPercent = oldPrice > unitPrice && oldPrice > 0
        ? (((oldPrice - unitPrice) / oldPrice) * 100).round()
        : 0;
    final canAdd = hero.available && (variant == null || variant.inStock);
    return ProductDetailState(
      status: ProductDetailStatus.loaded,
      imageIndex: imageIndex,
      showNutrition: showNutrition,
      variantIndex: variantIndex,
      quantity: quantity,
      unitPrice: unitPrice,
      oldPrice: oldPrice,
      discountPercent: discountPercent,
      heroImage: image,
      canAdd: canAdd,
      satisfaction: satisfaction,
    );
  }

  /// Re-derive the VIP/Mart-aware pricing when the global store mode flips.
  /// Driven by the screen's `BlocListener<StoreModeCubit>` because
  /// [StoreModeRepository] is a plain value source (no change notification).
  void onVipModeChanged() {
    if (_detail == null) return;
    safeEmit(
      _derive(
        _detail!,
        state.variantIndex,
        state.quantity,
        imageIndex: state.imageIndex,
        showNutrition: state.showNutrition,
        satisfaction: state.satisfaction,
      ),
    );
  }

  // ── Pager / nutrition toggle ────────────────────────────────────────────────
  void onPageChanged(int i) {
    final showNutrition = hasNutrition && i >= gallery.length;
    if (i == state.imageIndex && showNutrition == state.showNutrition) return;
    safeEmit(state.copyWith(imageIndex: i, showNutrition: showNutrition));
  }

  void showImages() {
    if (!state.showNutrition) return;
    final target = state.imageIndex.clamp(0, gallery.length - 1);
    safeEmit(state.copyWith(imageIndex: target, showNutrition: false));
  }

  void showNutritionPanel() {
    if (!hasNutrition || state.showNutrition) return;
    safeEmit(state.copyWith(imageIndex: gallery.length, showNutrition: true));
  }

  // ── Variant / quantity ──────────────────────────────────────────────────────
  void selectVariant(int index) {
    final hero = _detail?.product;
    if (hero == null ||
        index < 0 ||
        !hero.hasVariants ||
        index >= hero.variants.length ||
        index == state.variantIndex) {
      return;
    }
    safeEmit(
      _derive(
        _detail!,
        index,
        state.quantity,
        imageIndex: state.imageIndex,
        showNutrition: state.showNutrition,
        satisfaction: state.satisfaction,
      ),
    );
  }

  void increment() => setQuantity(state.quantity + 1);
  void decrement() => setQuantity(state.quantity - 1);

  void setQuantity(int quantity) {
    if (_detail == null) return;
    final q = quantity < 1 ? 1 : quantity;
    if (q == state.quantity) return;
    safeEmit(
      _derive(
        _detail!,
        state.variantIndex,
        q,
        imageIndex: state.imageIndex,
        showNutrition: state.showNutrition,
        satisfaction: state.satisfaction,
      ),
    );
  }

  // ── Feedback ────────────────────────────────────────────────────────────────
  void setSatisfaction(Satisfaction value) {
    if (value == state.satisfaction) return;
    safeEmit(state.copyWith(satisfaction: value));
  }

  // ── Cart ────────────────────────────────────────────────────────────────────
  void addToCart(CartCubit cart) {
    final hero = _detail?.product;
    if (hero == null || !state.canAdd) return;
    final vip = _storeMode.isVip;
    final variant = hero.hasVariants ? hero.variants[state.variantIndex] : null;
    cart.add(
      hero,
      kJameiaSupplierId,
      variant: variant,
      unitPrice: hero.priceFor(vip),
      qty: state.quantity,
    );
  }
}

/// Single state for the product-detail page — status + interactive fields. The
/// resolved [ProductDetail] section data is kept on the cubit (`detail`), not
/// here, so this stays small and Equatable-cheap.
class ProductDetailState extends Equatable {
  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.imageIndex = 0,
    this.showNutrition = false,
    this.variantIndex = 0,
    this.quantity = 1,
    this.unitPrice = 0,
    this.oldPrice = 0,
    this.discountPercent = 0,
    this.heroImage = '',
    this.canAdd = true,
    this.satisfaction = Satisfaction.none,
    this.error = '',
  });

  final ProductDetailStatus status;
  final int imageIndex;
  final bool showNutrition;
  final int variantIndex;
  final int quantity;
  final double unitPrice;
  final double oldPrice;
  final int discountPercent;
  final String heroImage;
  final bool canAdd;
  final Satisfaction satisfaction;
  final String error;

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    int? imageIndex,
    bool? showNutrition,
    int? variantIndex,
    int? quantity,
    double? unitPrice,
    double? oldPrice,
    int? discountPercent,
    String? heroImage,
    bool? canAdd,
    Satisfaction? satisfaction,
    String? error,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      imageIndex: imageIndex ?? this.imageIndex,
      showNutrition: showNutrition ?? this.showNutrition,
      variantIndex: variantIndex ?? this.variantIndex,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      oldPrice: oldPrice ?? this.oldPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      heroImage: heroImage ?? this.heroImage,
      canAdd: canAdd ?? this.canAdd,
      satisfaction: satisfaction ?? this.satisfaction,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    imageIndex,
    showNutrition,
    variantIndex,
    quantity,
    unitPrice,
    oldPrice,
    discountPercent,
    heroImage,
    canAdd,
    satisfaction,
    error,
  ];
}
