import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/coupon_entity.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../domain/entities/coupon_status.dart';
import '../coupon_card.dart';

/// Sliver of one history group: faded, stamped tickets that rise in, in
/// cascade, continuing the screen's order from [firstIndex].
class HistoryCouponsSection extends StatelessWidget {
  const HistoryCouponsSection({
    super.key,
    required this.coupons,
    required this.status,
    required this.firstIndex,
  });

  final List<CouponEntity> coupons;
  final CouponStatus status;
  final int firstIndex;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
      ),
      sliver: SliverList.separated(
        itemCount: coupons.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (_, i) => ScrollReveal(
          delay:
              CouponCard.cascadeStep *
              (firstIndex + i).clamp(0, CouponCard.maxCascadeSteps),
          child: CouponCard(coupon: coupons[i], status: status),
        ),
      ),
    );
  }
}
