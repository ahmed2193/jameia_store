import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';

/// Offline source for the `order_confirm_global` checkout screen. The live KeeTa
/// page hits `/api/order/confirm` + `/api/coupon/list`; here everything reads the
/// in-memory [KeetaRepository] catalogue (shop / address / coupons) and commits a
/// placed order back into it so it persists across restarts.
abstract class CheckoutLocalDataSource {
  Shop shopById(String id);
  KeetaAddress defaultAddress();

  /// Coupons the user can still apply (not yet used).
  List<Coupon> availableCoupons();

  /// Every coupon in the catalogue (used to validate an applied selection).
  List<Coupon> coupons();

  /// A fresh, non-colliding id for a placed order.
  String nextOrderId();

  /// Commit + persist a freshly-placed order; returns it.
  KeetaOrder addOrder(KeetaOrder order);
}

class CheckoutLocalDataSourceImpl implements CheckoutLocalDataSource {
  CheckoutLocalDataSourceImpl(this.catalog);

  final KeetaRepository catalog;

  @override
  Shop shopById(String id) {
    final shop = catalog.shopById(id);
    if (shop == null) throw StateError('Shop not found: $id');
    return shop;
  }

  @override
  KeetaAddress defaultAddress() => catalog.defaultAddress;

  @override
  List<Coupon> availableCoupons() =>
      catalog.coupons.where((c) => !c.used).toList(growable: false);

  @override
  List<Coupon> coupons() => catalog.coupons;

  @override
  String nextOrderId() => catalog.nextOrderId();

  @override
  KeetaOrder addOrder(KeetaOrder order) => catalog.addOrder(order);
}
