import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
// TODO(P2.9-boundary): CartState carries the core `CartItem` and `add`/`cart.lines`
// pass core `Product` / `CartItem` across feature boundaries (shop, product_details,
// checkout, orders all consume these core types), so this feature deliberately keeps
// the shared `core/data/models` DTOs instead of a framework-free entity.
import '../../../../core/data/models/models.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/cart_snapshot.dart';
import '../../domain/repositories/cart_repository.dart';

/// App-wide cart state. Single active cart scoped to one shop (Jameia replaces the
/// cart when you start ordering from a different shop). Registered as a long-lived
/// cubit at the app root.
///
/// Lines are keyed by [CartItem.lineKey] (product id, or `productId:variantSku`
/// when a specific SKU was chosen), so the same product in two sizes is two lines.
///
/// The public surface (methods + getters below) is unchanged from the original
/// bare cubit — the whole clean-arch + persistence rebuild lives behind it, so
/// no UI screen needed to change.
class CartState extends Equatable {
  /// Cart lines keyed by [CartItem.lineKey].
  final Map<String, CartItem> items;
  final String? shopId;

  const CartState({this.items = const {}, this.shopId});

  bool get isEmpty => items.isEmpty;

  int get totalQty => items.values.fold(0, (s, i) => s + i.qty);

  double get subtotal => items.values.fold(0.0, (s, i) => s + i.lineTotal);

  /// Quantity of an exact line (use [lineKey]; for a no-variant product that is
  /// just the product id).
  int qtyOf(String lineKey) => items[lineKey]?.qty ?? 0;

  /// Total quantity of a product across all of its variant lines — drives the
  /// stepper badge on a product row when the product has multiple SKUs.
  int qtyOfProduct(String productId) => items.values
      .where((i) => i.product.id == productId)
      .fold(0, (s, i) => s + i.qty);

  List<CartItem> get lines => items.values.toList(growable: false);

  CartState copyWith({Map<String, CartItem>? items, String? shopId}) =>
      CartState(items: items ?? this.items, shopId: shopId ?? this.shopId);

  @override
  List<Object?> get props => [items, shopId, totalQty, subtotal];
}

class CartCubit extends Cubit<CartState> with SafeCubitMixin<CartState> {
  final CartRepository _repository;

  /// App-root registration resolves the repository from the service locator.
  /// (`service_locator.dart` is a protected file we don't edit; its existing
  /// `registerFactory<CartCubit>(() => CartCubit())` call keeps working through
  /// this no-arg factory, while the [CartCubit.inject] constructor stays
  /// available for tests.) The five pass-through use cases were collapsed — the
  /// cubit now drives [CartRepository] directly.
  factory CartCubit() => CartCubit.inject(repository: sl<CartRepository>());

  CartCubit.inject({required CartRepository repository})
    : _repository = repository,
      super(const CartState()) {
    _hydrate();
  }

  /// Restore the persisted cart at startup (first frame shows the saved cart).
  Future<void> _hydrate() async => _emit(await _repository.getCart());

  /// Add [qty] units of a product (optionally a specific [variant]) to the cart.
  void add(
    Product product,
    String shopId, {
    ProductVariant? variant,
    double? unitPrice,
    int qty = 1,
  }) {
    _run(
      _repository.addLine(
        product: product,
        shopId: shopId,
        variant: variant,
        unitPrice: unitPrice,
        qty: qty,
      ),
    );
  }

  /// Remove one unit of the line identified by [lineKey] (a product id, or
  /// `productId:variantSku`). Removes the line when it hits zero.
  void remove(String lineKey) {
    final q = state.qtyOf(lineKey);
    if (q <= 0) return;
    _run(_repository.updateQty(lineKey: lineKey, qty: q - 1));
  }

  /// Remove one unit of any line belonging to [productId] (used by a multi-SKU
  /// product row's "−", which is not variant-specific).
  void removeProduct(String productId) {
    for (final e in state.items.entries) {
      if (e.value.product.id == productId) {
        remove(e.key);
        return;
      }
    }
  }

  /// Remove an entire line regardless of its quantity (swipe-to-delete etc.).
  void removeLine(String lineKey) =>
      _run(_repository.removeLine(lineKey: lineKey));

  void clear() => _run(_repository.clear());

  /// B2 — resolve a router-resolvable checkout shop id for the active cart,
  /// routing the catalogue read through the repository so the presentation layer
  /// (Cart preview → Checkout) never reaches into `core/data/jameia_repository.dart`.
  String? resolveCheckoutShopId() => _repository.checkoutShopId(state.shopId);

  Future<void> _run(Future<Either<Failure, CartSnapshot>> op) async =>
      _emit(await op);

  void _emit(Either<Failure, CartSnapshot> either) {
    either.fold(
      // Offline cart: on the rare persistence failure keep the last good state.
      (_) {},
      (snap) => safeEmit(CartState(items: snap.items, shopId: snap.shopId)),
    );
  }
}
