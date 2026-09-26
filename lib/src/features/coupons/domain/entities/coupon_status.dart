/// Which wallet bucket a coupon card renders from: an available coupon can be
/// used; a used or expired one is shown faded under its stamp.
enum CouponStatus {
  available,
  used,
  expired;

  bool get isAvailable => this == CouponStatus.available;
}
