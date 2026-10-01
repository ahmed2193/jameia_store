import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/domain/entities/coupon_entity.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/coupon_dates.dart';
import '../../domain/entities/coupon_status.dart';
import 'coupon_fade.dart';
import 'coupon_info_chip.dart';

/// Body of a coupon ticket: the title and subtitle with an optional
/// [trailing] control at their end (the "Use" pill), then
/// the conditions as chips across the full width (minimum spend when there is
/// one, then the date).
///
/// The date chip follows [status]: "Valid till …" for an available coupon,
/// "Used …" / "Expired …" (localized, the date taken out of the label) for a
/// spent one, which is also painted in the spent-coupon greys ([CouponFade]).
class CouponBody extends StatelessWidget {
  const CouponBody({
    super.key,
    required this.coupon,
    this.status = CouponStatus.available,
    this.trailing,
  });

  final CouponEntity coupon;
  final CouponStatus status;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    final subtitle = coupon.subtitleFor(languageCode);
    final faded = !status.isAvailable;
    final dateLabel = _dateLabel();
    final end = trailing;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s12,
        AppSpacing.s12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.titleFor(languageCode),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingMedium.copyWith(
                        fontWeight: AppTextStyles.bold,
                        color: CouponFade.of(
                          AppColors.primaryText,
                          faded: faded,
                        ),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: CouponFade.of(
                            AppColors.secondaryText,
                            faded: faded,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (end != null) ...[const SizedBox(width: AppSpacing.s8), end],
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          Wrap(
            spacing: AppSpacing.s6,
            runSpacing: AppSpacing.s6,
            children: [
              if (coupon.minSpend > 0)
                CouponInfoChip(
                  icon: HeroIcons.bag,
                  faded: faded,
                  label: 'coupons.min_amount'.tr(
                    namedArgs: {'value': Formatters.price(coupon.minSpend)},
                  ),
                ),
              if (dateLabel != null)
                CouponInfoChip(
                  icon: HeroIcons.clock,
                  faded: faded,
                  label: dateLabel,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// The date chip's text, or `null` when there is no date to show. The date
  /// is isolated: an ISO date inside Arabic text would otherwise reorder its
  /// parts.
  String? _dateLabel() {
    if (status.isAvailable) {
      if (coupon.expiry.isEmpty) return null;
      return 'coupons.valid_till'.tr(
        namedArgs: {'date': Formatters.isolate(coupon.expiry)},
      );
    }
    final date = coupon.expiryDateLabel;
    if (date == null) return null;
    final key = status == CouponStatus.used
        ? 'coupons.used_on'
        : 'coupons.expired_on';
    return key.tr(namedArgs: {'date': Formatters.isolate(date)});
  }
}
