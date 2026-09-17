import '../../../../core/data/models/models.dart';
import '../../domain/entities/coupon.dart';

/// DTO → entity mapping for coupons. Lives in the data layer, so the framework
/// coupling of the core [Coupon] DTO (its `easy_localization`-backed display
/// getters) never crosses into the domain [CouponEntity], which stays plain
/// Dart. Display resolution happens in presentation, off the raw fields carried
/// here.
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

/// Convenience for mapping the whole list.
extension CouponListMapper on List<Coupon> {
  List<CouponEntity> toEntities() => map((c) => c.toEntity()).toList();
}
