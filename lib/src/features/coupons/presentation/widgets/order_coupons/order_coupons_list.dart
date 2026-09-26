import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/coupon_entity.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../coupon_card.dart';
import '../coupons_empty_view.dart';
import 'order_coupon_card.dart';
import 'order_no_coupon_option.dart';

/// The checkout picker's list: every available coupon as a selectable ticket,
/// then "Don't use a coupon"; they rise in, in cascade. [onSelect] gets the
/// tapped coupon's id (`null` for "Don't use"). No available coupon → the
/// friendly empty state.
class OrderCouponsList extends StatelessWidget {
  const OrderCouponsList({
    super.key,
    required this.coupons,
    required this.selectedId,
    required this.onSelect,
  });

  final List<CouponEntity> coupons;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    if (coupons.isEmpty) {
      return CouponsEmptyView(
        message: 'coupons.none_for_order'.tr(),
        icon: Icons.local_activity_outlined,
      );
    }
    return ContentClamp(
      child: ListView.separated(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s16,
          AppSpacing.s12,
          AppSpacing.s16,
          AppSpacing.s16,
        ),
        // +1 trailing row: the explicit "don't use a coupon" option.
        itemCount: coupons.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (_, i) {
          final delay =
              CouponCard.cascadeStep * i.clamp(0, CouponCard.maxCascadeSteps);
          if (i == coupons.length) {
            return ScrollReveal(
              delay: delay,
              child: OrderNoCouponOption(
                selected: selectedId == null,
                onTap: () => onSelect(null),
              ),
            );
          }
          final coupon = coupons[i];
          return ScrollReveal(
            delay: delay,
            child: OrderCouponCard(
              coupon: coupon,
              selected: selectedId == coupon.id,
              onTap: () => onSelect(coupon.id),
            ),
          );
        },
      ),
    );
  }
}
