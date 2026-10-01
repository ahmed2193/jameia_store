import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/pop_scale.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';
import 'coupon_stub.dart';

/// The warm ticket disc before a coupon's title in its detail sheet; it pops
/// in once with the sheet.
class CouponTicketDisc extends StatelessWidget {
  const CouponTicketDisc({super.key});

  static const double _disc = AppSize.s44;

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: PopScale.onMount(
        child: SizedBox.square(
          dimension: _disc,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: CouponStub.gradient,
              ),
            ),
            child: HeroIcon(
              HeroIcons.voucher,
              size: AppSize.s22,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
