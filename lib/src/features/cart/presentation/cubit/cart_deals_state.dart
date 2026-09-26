import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/error/failures.dart';

enum CartDealsStatus { initial, loading, loaded, error }

/// The "Buy more, save more" sheet: which deal is selected and the products
/// listed under it.
class CartDealsState extends Equatable {
  const CartDealsState({
    this.selectedOfferId,
    this.status = CartDealsStatus.initial,
    this.products = const <CatalogProductEntity>[],
    this.failure,
  });

  final String? selectedOfferId;
  final CartDealsStatus status;
  final List<CatalogProductEntity> products;

  /// Transient — cleared on every [copyWith]; the sheet shows
  /// `failure.localizedMessage` with a retry while [status] is `error`.
  final Failure? failure;

  bool get isLoading =>
      status == CartDealsStatus.initial || status == CartDealsStatus.loading;
  bool get isEmpty => status == CartDealsStatus.loaded && products.isEmpty;

  CartDealsState copyWith({
    String? selectedOfferId,
    CartDealsStatus? status,
    List<CatalogProductEntity>? products,
    Failure? failure,
  }) => CartDealsState(
    selectedOfferId: selectedOfferId ?? this.selectedOfferId,
    status: status ?? this.status,
    products: products ?? this.products,
    failure: failure,
  );

  @override
  List<Object?> get props => [selectedOfferId, status, products, failure];
}
