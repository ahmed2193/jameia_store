import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/catalog_variant_entity.dart';
import '../../../../core/domain/entities/offer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product_detail.dart';

enum ProductDetailStatus { initial, loading, loaded, error }

class ProductDetailState extends Equatable {
  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.preview,
    this.detail,
    this.selectedVariantId,
    this.quantity = minQuantity,
    this.imageIndex = 0,
    this.promo,
    this.failure,
  });

  static const int minQuantity = 1;

  /// "Only N left" shows from this many units of the selection down.
  static const int lowStockThreshold = 5;
  static const int _notFound = 404;

  final ProductDetailStatus status;

  /// The list card the customer tapped: painted while the detail loads.
  final CatalogProductEntity? preview;
  final ProductDetail? detail;
  final String? selectedVariantId;
  final int quantity;

  /// Page of the gallery pager.
  final int imageIndex;

  /// The cart offer that counts this product ("2 KWD off dairy (3 items)"),
  /// the buy bar's promo tag; null when none does or the offers could not
  /// be read (the page never fails over it).
  final OfferEntity? promo;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  bool get isLoaded => status == ProductDetailStatus.loaded;

  /// The slug does not exist (any more): an empty state, not an error + retry.
  bool get isNotFound {
    final current = failure;
    return status == ProductDetailStatus.error &&
        current is ServerFailure &&
        current.statusCode == _notFound;
  }

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

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    ProductDetail? detail,
    String? selectedVariantId,
    int? quantity,
    int? imageIndex,
    OfferEntity? promo,
    Failure? failure,
  }) => ProductDetailState(
    status: status ?? this.status,
    preview: preview,
    detail: detail ?? this.detail,
    selectedVariantId: selectedVariantId ?? this.selectedVariantId,
    quantity: quantity ?? this.quantity,
    imageIndex: imageIndex ?? this.imageIndex,
    promo: promo ?? this.promo,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    preview,
    detail,
    selectedVariantId,
    quantity,
    imageIndex,
    promo,
    failure,
  ];
}
