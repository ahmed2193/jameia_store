import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/coupon_entity.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../domain/entities/coupon_status.dart';
import 'coupon_body.dart';
import 'coupon_rule_sheet.dart';
import 'coupon_stamp.dart';
import 'coupon_stub.dart';
import 'coupon_ticket.dart';
import 'coupon_use_button.dart';

/// A coupon of the wallet as a ticket. Tapping it opens its detail sheet.
///
/// An available coupon shows its amount at once (never a count-up on open)
/// and carries the
/// "Use" pill ([onUse]; it shimmers now and then while [shimmers]). A used or
/// expired coupon is faded to grey under a "USED" / "EXPIRED" stamp and has
/// no action.
class CouponCard extends StatelessWidget {
  const CouponCard({
    super.key,
    required this.coupon,
    required this.status,
    this.onUse,
    this.shimmers = false,
  });

  final CouponEntity coupon;
  final CouponStatus status;
  final VoidCallback? onUse;
  final bool shimmers;

  /// Only the first few "Use" pills shimmer (the screen's loop budget).
  static const int maxShimmering = 3;

  @override
  Widget build(BuildContext context) {
    final available = status.isAvailable;
    final faded = !available;
    final use = onUse;
    // The boundary keeps the ticket's own layer while the press scale, the
    // list's reveal slide and the stamp's pop animate around it: they
    // re-composite it instead of repainting the clip, outline and shadow
    // every frame.
    final ticket = RepaintBoundary(
      child: CouponTicket(
        faded: faded,
        stub: CouponStub(amount: coupon.amount, faded: faded),
        body: CouponBody(
          coupon: coupon,
          status: status,
          trailing: available && use != null
              ? CouponUseButton(onPressed: use, shimmers: shimmers)
              : null,
        ),
      ),
    );
    return Semantics(
      button: true,
      child: PressScale(
        // Opening the rules sheet is navigation: no haptic (§9.5).
        onTap: () => CouponRuleSheet.show(context, coupon),
        child: available
            ? ticket
            : Stack(
                children: [
                  ticket,
                  PositionedDirectional(
                    end: AppSpacing.s12,
                    top: AppSpacing.s16,
                    child: CouponStamp(
                      label: status == CouponStatus.used
                          ? 'coupons.stamp_used'.tr()
                          : 'coupons.stamp_expired'.tr(),
                      color: status == CouponStatus.used
                          ? AppColors.accent2Dark
                          : AppColors.finalPrice,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
