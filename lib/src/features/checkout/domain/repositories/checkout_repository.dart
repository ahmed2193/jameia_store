import 'package:dartz/dartz.dart';

import '../../../../core/data/models/models.dart' show CartItem;
import '../../../../core/error/failures.dart';
import '../entities/checkout_context.dart';
import '../entities/checkout_draft.dart';
import '../entities/coupon_entity.dart';
import '../entities/jameia_order_entity.dart';
import '../entities/shop_entity.dart';

/// Read/commit boundary for the `order_confirm_global` checkout screen. Offline,
/// everything resolves from the in-memory catalogue, mapped to framework-free
/// entities; the methods still return `Either<Failure, T>` so the presentation
/// layer handles failure uniformly.
abstract class CheckoutRepository {
  /// First-frame context (shop + delivery address + available-coupon count).
  Future<Either<Failure, CheckoutContext>> getContext(String shopId);

  /// Validate the picked coupon id against the available catalogue coupons and
  /// return the applied [CouponEntity], or a failure when it is used / no longer
  /// available. Takes the id only — the coupon object itself comes back across
  /// the coupons-picker route as a core DTO (kept in the screen).
  Future<Either<Failure, CouponEntity>> applyCoupon(String couponId);

  /// Build the real order from the draft + cart snapshot, persist it (so it
  /// survives restarts and shows in the orders list), and return its summary.
  ///
  /// [lines] stays the core [CartItem] type — it crosses the cart-feature
  /// boundary (supplied by `CartCubit`); the data layer maps it to order items.
  Future<Either<Failure, JameiaOrderEntity>> placeOrder({
    required ShopEntity shop,
    required List<CartItem> lines,
    required double subtotal,
    required CheckoutDraft draft,
  });
}
