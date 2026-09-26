import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/coupon_buckets.dart';
import '../coupon_stub.dart';
import 'coupons_summary_badge.dart';
import 'coupons_summary_empty.dart';
import 'coupons_summary_savings.dart';

/// Warm amber → orange card at the top of My coupons: how much the available
/// coupons can save (counting up from 0), how many are ready, and the glowing
/// ticket badge. With nothing available it says new coupons will land here.
class CouponsSummaryCard extends StatelessWidget {
  const CouponsSummaryCard({super.key, required this.buckets});

  final CouponBuckets buckets;

  static const double _shadowAlpha = 0.22;
  static const Offset _shadowOffset = Offset(0, AppSpacing.s8);
  static final List<BoxShadow> _shadow = [
    BoxShadow(
      color: kJameiaPillPin.withValues(alpha: _shadowAlpha),
      offset: _shadowOffset,
      blurRadius: AppSize.s24,
      spreadRadius: -AppSpacing.s6,
    ),
  ];
  static const double _ringAlpha = 0.14;
  static final Color _ring = AppColors.white.withValues(alpha: _ringAlpha);
  static const double _ringOverhang = -AppSpacing.s48;
  static const double _ringWidth = AppSpacing.s24;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.r2);
    final ready = buckets.available.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _shadow,
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: CouponStub.gradient,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            PositionedDirectional(
              top: _ringOverhang,
              end: _ringOverhang,
              child: SizedBox.square(
                dimension: AppSize.s180,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _ring, width: _ringWidth),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s20,
                AppSpacing.s16,
                AppSpacing.s8,
                AppSpacing.s16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ready > 0
                        ? CouponsSummarySavings(
                            savings: buckets.savingsUpTo,
                            ready: ready,
                          )
                        : const CouponsSummaryEmpty(),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  const CouponsSummaryBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
