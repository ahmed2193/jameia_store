import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/data/models/models.dart';

/// App-wide cart state. Single active cart scoped to one shop (KeeTa replaces the
/// cart when you start ordering from a different shop). Registered as a long-lived
/// cubit at the app root.
class CartState extends Equatable {
  /// Cart lines keyed by product id.
  final Map<String, CartItem> items;
  final String? shopId;

  const CartState({this.items = const {}, this.shopId});

  bool get isEmpty => items.isEmpty;

  int get totalQty => items.values.fold(0, (s, i) => s + i.qty);

  double get subtotal =>
      items.values.fold(0.0, (s, i) => s + i.lineTotal);

  int qtyOf(String productId) => items[productId]?.qty ?? 0;

  List<CartItem> get lines => items.values.toList(growable: false);

  CartState copyWith({Map<String, CartItem>? items, String? shopId}) =>
      CartState(items: items ?? this.items, shopId: shopId ?? this.shopId);

  @override
  List<Object?> get props => [items, shopId, totalQty, subtotal];
}

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  void add(Product product, String shopId) {
    // Starting a cart in a new shop clears the previous one.
    final base = (state.shopId != null && state.shopId != shopId)
        ? <String, CartItem>{}
        : Map<String, CartItem>.from(state.items);

    final existing = base[product.id];
    if (existing == null) {
      base[product.id] = CartItem(product: product, shopId: shopId, qty: 1);
    } else {
      existing.qty += 1;
    }
    emit(CartState(items: base, shopId: shopId));
  }

  void remove(String productId) {
    final base = Map<String, CartItem>.from(state.items);
    final existing = base[productId];
    if (existing == null) return;
    if (existing.qty <= 1) {
      base.remove(productId);
    } else {
      existing.qty -= 1;
    }
    emit(CartState(items: base, shopId: base.isEmpty ? null : state.shopId));
  }

  void clear() => emit(const CartState());
}
