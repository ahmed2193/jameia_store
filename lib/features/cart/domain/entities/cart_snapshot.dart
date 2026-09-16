import 'package:equatable/equatable.dart';

import '../../../../core/data/models/models.dart';

/// Immutable value describing the whole cart after an operation — the domain
/// result type every [CartRepository] method returns. The presentation layer
/// (`CartCubit`) maps this to `CartState`; keeping a distinct domain entity
/// stops the data layer from depending on presentation.
class CartSnapshot extends Equatable {
  /// Cart lines keyed by [CartItem.lineKey].
  final Map<String, CartItem> items;

  /// The shop this cart belongs to (KeeTa scopes one cart to one shop), or null
  /// when the cart is empty.
  final String? shopId;

  const CartSnapshot({this.items = const {}, this.shopId});

  @override
  List<Object?> get props => [items, shopId];
}
