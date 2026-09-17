import 'package:dartz/dartz.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/checkout_context.dart';
import '../../domain/entities/checkout_draft.dart';
import '../../domain/entities/coupon_entity.dart';
import '../../domain/entities/jameia_order_entity.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../datasources/checkout_local_data_source.dart';
import '../mappers/address_mapper.dart';
import '../mappers/coupon_mapper.dart';
import '../mappers/order_mapper.dart';
import '../mappers/shop_mapper.dart';

/// Offline checkout repository — reads the [CheckoutLocalDataSource] DTOs, maps
/// them to framework-free entities, and wraps each result in
/// `Either<Failure, T>`, mapping any error to [CacheFailure].
class CheckoutRepositoryImpl implements CheckoutRepository {
  CheckoutRepositoryImpl({required this.local});

  final CheckoutLocalDataSource local;

  @override
  Future<Either<Failure, CheckoutContext>> getContext(String shopId) async {
    try {
      return Right(
        CheckoutContext(
          shop: local.shopById(shopId).toEntity(),
          address: local.defaultAddress().toEntity(),
          availableCouponCount: local.availableCoupons().length,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CouponEntity>> applyCoupon(String couponId) async {
    try {
      for (final c in local.coupons()) {
        if (c.id == couponId && !c.used) return Right(c.toEntity());
      }
      return const Left(CacheFailure('Coupon is no longer available'));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, JameiaOrderEntity>> placeOrder({
    required ShopEntity shop,
    required List<CartItem> lines,
    required double subtotal,
    required CheckoutDraft draft,
  }) async {
    try {
      final total = draft.totalFor(subtotal, shop.effectiveDeliveryFee);
      final items = lines
          .map(
            (l) =>
                OrderItem(name: l.displayName, qty: l.qty, price: l.unitPrice),
          )
          .toList(growable: false);
      final now = DateTime.now();
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');
      final order = JameiaOrder(
        id: local.nextOrderId(),
        shopName: shop.name,
        shopNameAr: shop.nameAr,
        shopId: shop.id,
        shopLogo: shop.logo,
        status: 'preparing',
        statusStep: 1,
        total: total,
        date: 'Today, $hh:$mm',
        items: items,
        rider: const Rider(
          name: 'Yousef A.',
          phone: '+965 5012 3456',
          vehicle: 'motorbike',
        ),
      );
      return Right(local.addOrder(order).toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
