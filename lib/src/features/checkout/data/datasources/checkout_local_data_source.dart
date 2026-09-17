import '../../../../core/data/jameia_repository.dart';
import '../../../../core/data/models/models.dart';

/// Offline source for the `order_confirm_global` checkout screen. The live Jameia
/// page hits `/api/order/confirm` + `/api/coupon/list`; here everything reads the
/// in-memory [JameiaRepository] catalogue (shop / address / coupons) and commits a
/// placed order back into it so it persists across restarts.
abstract class CheckoutLocalDataSource {
  Shop shopById(String id);
  JameiaAddress defaultAddress();

  /// Coupons the user can still apply (not yet used).
  List<Coupon> availableCoupons();

  /// Every coupon in the catalogue (used to validate an applied selection).
  List<Coupon> coupons();

  /// A fresh, non-colliding id for a placed order.
  String nextOrderId();

  /// Commit + persist a freshly-placed order; returns it.
  JameiaOrder addOrder(JameiaOrder order);
}

class CheckoutLocalDataSourceImpl implements CheckoutLocalDataSource {
  CheckoutLocalDataSourceImpl(this.catalog);

  final JameiaRepository catalog;

  @override
  Shop shopById(String id) {
    final shop = catalog.shopById(id);
    if (shop == null) throw StateError('Shop not found: $id');
    return shop;
  }

  @override
  JameiaAddress defaultAddress() => catalog.defaultAddress;

  @override
  List<Coupon> availableCoupons() =>
      catalog.coupons.where((c) => !c.used).toList(growable: false);

  @override
  List<Coupon> coupons() => catalog.coupons;

  @override
  String nextOrderId() => catalog.nextOrderId();

  @override
  JameiaOrder addOrder(JameiaOrder order) => catalog.addOrder(order);
}
