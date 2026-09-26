import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/coupon_entity.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../domain/entities/coupon_status.dart';
import '../coupon_card.dart';
import '../coupons_empty_view.dart';

/// One tab of My coupons: its coupons as tickets that rise in, in cascade
/// (the ones below the fold as they scroll into view), or the friendly empty
/// state. "Use" on an available coupon returns to the shell to go shopping.
class CouponsTabList extends StatelessWidget {
  const CouponsTabList({
    super.key,
    required this.coupons,
    required this.status,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  final List<CouponEntity> coupons;
  final CouponStatus status;
  final String emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return CouponsEmptyView(message: emptyMessage, icon: emptyIcon);
    }
    return ListView.separated(
      key: PageStorageKey<CouponStatus>(status),
      padding: EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s4,
        AppSpacing.s16,
        AppSpacing.s24 + MediaQuery.paddingOf(context).bottom,
      ),
      itemCount: coupons.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, i) => ScrollReveal(
        delay: CouponCard.cascadeStep * i.clamp(0, CouponCard.maxCascadeSteps),
        child: CouponCard(
          coupon: coupons[i],
          status: status,
          onUse: status.isAvailable ? () => context.go(Routes.shell) : null,
          shimmers: i < CouponCard.maxShimmering,
        ),
      ),
    );
  }
}
