import '../../domain/entities/coupon_entity.dart';
import '../models/coupon.dart';

/// `Coupon` DTO → [CouponEntity].
///
/// Read-only: coupons are only listed / looked up by id (no repository write
/// API takes a coupon), so no reverse mapper exists.
extension CouponMapper on Coupon {
  CouponEntity toEntity() => CouponEntity(
    id: id,
    title: title,
    titleAr: titleAr,
    subtitle: subtitle,
    subtitleAr: subtitleAr,
    amount: amount,
    minSpend: minSpend,
    expiry: expiry,
    used: used,
  );
}

extension CouponListMapper on List<Coupon> {
  List<CouponEntity> toEntities() =>
      map((c) => c.toEntity()).toList(growable: false);
}
