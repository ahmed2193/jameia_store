import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/catalog_variant_entity.dart';
import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../domain/entities/product_detail.dart';

class ProductDetailState extends Equatable
    implements ScreenLoadState<ProductDetailState> {
  const ProductDetailState({
    this.load = const ScreenLoad(),
    this.preview,
    this.detail,
    this.selectedVariantId,
    this.quantity = minQuantity,
    this.imageIndex = 0,
    this.promo,
  });

  static const int minQuantity = 1;

  /// "Only N left" shows from this many units of the selection down.
  static const int lowStockThreshold = 5;

  /// The product's read, how fresh it is (the device copy, a failed
  /// refresh … — stale prices and stock say so) and the failure that goes
  /// with them (not found, offline, error).
  @override
  final ScreenLoad load;

  /// The list card the customer tapped: painted while the detail loads.
  final CatalogProductEntity? preview;
  final ProductDetail? detail;
  final String? selectedVariantId;
  final int quantity;

  /// Page of the gallery pager.
  final int imageIndex;

  /// The cart offer that counts this product ("2 KWD off dairy (3 items)"),
  /// the offer tag under the product's name; null when none does or the
  /// offers could not be read (the page never fails over it).
  final OfferEntity? promo;

  LoadPhase get status => load.phase;
  DataFreshness get freshness => load.freshness;
  Failure? get failure => load.failure;
  bool get isLoaded => load.isLoaded;

  /// The slug does not exist (any more): an empty state, not an error + retry.
  bool get isNotFound => load.isNotFound;

  CatalogVariantEntity? get selectedVariant =>
      detail?.variantById(selectedVariantId);

  bool get canAdd => detail?.canAdd(selectedVariant) ?? false;

  /// Upper bound of the quantity stepper: what is in stock (at least one, so
  /// the stepper never collapses).
  int get maxQuantity {
    final stock = detail?.stockOf(selectedVariant) ?? minQuantity;
    return stock < minQuantity ? minQuantity : stock;
  }

  /// Units of the selection left when they are running out (1 up to
  /// [lowStockThreshold]); `null` with plenty, none, or nothing loaded.
  int? get lowStockLeft {
    final stock = detail?.stockOf(selectedVariant) ?? 0;
    return stock > 0 && stock <= lowStockThreshold ? stock : null;
  }

  @override
  ProductDetailState withLoad(ScreenLoad load) => copyWith(load: load);

  ProductDetailState copyWith({
    ScreenLoad? load,
    ProductDetail? detail,
    String? selectedVariantId,
    int? quantity,
    int? imageIndex,
    OfferEntity? promo,
  }) => ProductDetailState(
    load: load ?? this.load.settled(),
    preview: preview,
    detail: detail ?? this.detail,
    selectedVariantId: selectedVariantId ?? this.selectedVariantId,
    quantity: quantity ?? this.quantity,
    imageIndex: imageIndex ?? this.imageIndex,
    promo: promo ?? this.promo,
  );

  @override
  List<Object?> get props => [
    load,
    preview,
    detail,
    selectedVariantId,
    quantity,
    imageIndex,
    promo,
  ];
}
