import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/domain/entities/coupon_entity.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../coupon_body.dart';
import '../coupon_stub.dart';
import '../coupon_ticket.dart';
import 'coupon_select_check.dart';

/// A coupon of the checkout picker: the whole ticket is the tap target (it
/// dips, with a selection haptic). When [selected] the ticket lifts a little,
/// its outline turns into the accent ring and the check pops in.
class OrderCouponCard extends StatelessWidget {
  const OrderCouponCard({
    super.key,
    required this.coupon,
    required this.selected,
    required this.onTap,
  });

  final CouponEntity coupon;
  final bool selected;
  final VoidCallback onTap;

  static const double _lift = AppSpacing.s4;

  @override
  Widget build(BuildContext context) {
    final stub = CouponStub(amount: coupon.amount);
    final body = CouponBody(
      coupon: coupon,
      trailing: CouponSelectCheck(selected: selected),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        onTap: onTap,
        haptic: HapticKind.selection,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: selected ? 1 : 0),
          duration: MotionGuard.duration(context, AppMotion.medium),
          curve: AppMotion.emphasizedDecelerate,
          // The boundary lets the press scale and the list's reveal slide
          // re-composite the ticket instead of repainting it every frame.
          builder: (_, t, _) => Transform.translate(
            offset: Offset(0, -_lift * t),
            child: RepaintBoundary(
              child: CouponTicket(stub: stub, body: body, highlight: t),
            ),
          ),
        ),
      ),
    );
  }
}
