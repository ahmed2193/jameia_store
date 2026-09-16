import 'package:easy_localization/easy_localization.dart';

import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/motion/motion.dart';
import '../../domain/entities/refund_detail.dart';

/// Offline source for the order lifecycle. The live KeeTa pages hit
/// `/api/order`, `v1/order/status`, `v1/order/refund`, `v1/ugc/reviews/submit`
/// etc.; here every read resolves from the in-memory [KeetaRepository] and the
/// mutations are accepted no-ops (the catalogue owns no order-mutation API).
///
/// `.tr()` is resolved at call time (not cached) so each page open renders in
/// the current locale — matching the old page-scoped-cubit behavior.
abstract class OrdersLocalDataSource {
  /// The full order list (newest first).
  List<KeetaOrder> orders();

  /// One order by id (throws when the id is unknown).
  KeetaOrder orderById(String id);

  /// The most recent order (`orders.first`).
  KeetaOrder firstOrder();

  /// The user's default delivery address.
  KeetaAddress defaultAddress();

  /// Resolve the navigable catalogue shop id for [order] — its own `shopId` when
  /// set (placed orders), else an (English) shop-name match, else the first shop.
  /// Centralizes the lookup that used to live statically in the order card.
  String navigableShopId(KeetaOrder order);

  /// The derived refund progress / breakdown for [id].
  RefundDetail refundDetail(String id);

  /// Accept a submitted review (simulated network latency, then no-op).
  Future<void> submitReview({
    required String orderId,
    required int stars,
    required Set<String> likedTags,
    required Set<String> likedProducts,
    required int photoCount,
  });

  /// Accept a submitted refund request (no-op).
  Future<void> submitRefund({
    required String orderId,
    String? reason,
    required Map<int, int> selectedQty,
    required String description,
    required int photoCount,
    required double amount,
  });

  /// Accept a cancel request (no-op — no cancel mutation exists offline).
  Future<void> cancelOrder({required String orderId, String? reason});
}

class OrdersLocalDataSourceImpl implements OrdersLocalDataSource {
  OrdersLocalDataSourceImpl(this.catalog);

  final KeetaRepository catalog;

  @override
  List<KeetaOrder> orders() => catalog.orders;

  @override
  KeetaOrder orderById(String id) => catalog.orderById(id);

  @override
  KeetaOrder firstOrder() => catalog.orders.first;

  @override
  KeetaAddress defaultAddress() => catalog.defaultAddress;

  @override
  String navigableShopId(KeetaOrder order) {
    // Placed orders carry the real catalogue shop id; seed/demo orders fall back
    // to an (English) name match, else the first shop.
    if (order.shopId.isNotEmpty) return order.shopId;
    final shops = catalog.shops;
    return shops
        .firstWhere((s) => s.name == order.shopName, orElse: () => shops.first)
        .id;
  }

  @override
  RefundDetail refundDetail(String id) {
    final order = catalog.orderById(id);
    // A cancelled order reads as fully refunded; anything else is mid-process.
    final fullyRefunded = order.status == 'cancelled';
    const deliveryRefund = 0.500;
    const voucher = 1.000;
    final itemRefund = order.total - deliveryRefund;
    return RefundDetail(
      orderId: order.id,
      shopName: order.displayShopName,
      stage: fullyRefunded ? RefundDetail.stageCount : 2,
      etaLabel:
          fullyRefunded ? 'orders.eta_done'.tr() : 'orders.eta_estimate'.tr(),
      itemRefund: itemRefund < 0 ? order.total : itemRefund,
      deliveryRefund: deliveryRefund,
      voucherDeduction: voucher,
      method: 'orders.refund_method_value'.tr(),
    );
  }

  @override
  Future<void> submitReview({
    required String orderId,
    required int stars,
    required Set<String> likedTags,
    required Set<String> likedProducts,
    required int photoCount,
  }) async {
    // Offline stand-in for the review POST — a short latency so the submit
    // button shows its spinner, then accepted (no store to mutate).
    await Future<void>.delayed(AppMotion.medium);
  }

  @override
  Future<void> submitRefund({
    required String orderId,
    String? reason,
    required Map<int, int> selectedQty,
    required String description,
    required int photoCount,
    required double amount,
  }) async {
    // Accepted no-op (offline).
  }

  @override
  Future<void> cancelOrder({required String orderId, String? reason}) async {
    // Accepted no-op — the in-memory catalogue exposes no cancel mutation.
  }
}
