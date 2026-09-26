import '../../../../core/domain/entities/coupon_entity.dart';

/// The calendar date carried by a coupon's expiry label.
///
/// The offline data writes the date on its own for a live coupon
/// (`2026-12-31`) and after an English marker for a spent one
/// (`Used 2026-05-01`, `Expired 2026-01-15`). These selectors pull the ISO
/// `yyyy-mm-dd` part out, so the wallet can compare it with today and the UI
/// can show it without the English marker.
extension CouponDates on CouponEntity {
  static final RegExp _isoDate = RegExp(r'\d{4}-\d{2}-\d{2}');

  /// The first `yyyy-mm-dd` in [CouponEntity.expiry], or `null` when the
  /// label has none.
  String? get expiryDateLabel => _isoDate.firstMatch(expiry)?.group(0);

  /// [expiryDateLabel] as a date (midnight, local), or `null`.
  DateTime? get expiryDate {
    final label = expiryDateLabel;
    return label == null ? null : DateTime.tryParse(label);
  }
}
