import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';

/// `loading` until the rail is settled; then it either shows ([ready]) or
/// stays away for good ([hidden]: no products, a failure, or a reply too
/// slow to arrive before the page's content).
enum CheckoutRailStatus { loading, ready, hidden }

class CheckoutRailState extends Equatable {
  const CheckoutRailState({
    this.status = CheckoutRailStatus.loading,
    this.products = const <CatalogProductEntity>[],
  });

  final CheckoutRailStatus status;
  final List<CatalogProductEntity> products;

  bool get isSettled => status != CheckoutRailStatus.loading;

  @override
  List<Object?> get props => [status, products];
}
