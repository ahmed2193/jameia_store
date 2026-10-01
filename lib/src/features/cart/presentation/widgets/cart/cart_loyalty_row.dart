import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icon_tone.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/domain/entities/cart_loyalty_entity.dart';
import '../../../../../core/motion/change_bump.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/hero_list_row.dart';
import '../../../../../core/widgets/hero_text_link.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../domain/entities/cart_snapshot.dart';
import '../../cubit/cart_cubit.dart';
import 'cart_discount_amount.dart';

/// Loyalty points against the cart: "use N points", or the applied points +
/// discount with a remove link. The options section decides whether it
/// shows (a signed-in customer with points, or points applied). The star
/// fills with a bump when the points land or leave.
class CartLoyaltyRow extends StatelessWidget {
  const CartLoyaltyRow({super.key});

  @override
  Widget build(BuildContext context) {
    final available = context.select<AuthSessionCubit, int>(
      (session) => session.state.customer?.loyaltyPoints ?? 0,
    );
    final loyalty = context.select<CartCubit, CartLoyaltyEntity>(
      (cubit) => cubit.state.cart.loyalty,
    );
    final busy = context.select<CartCubit, bool>(
      (cubit) => cubit.state.busyAction == CartAction.loyalty,
    );
    final applied = loyalty.isApplied;
    return HeroListRow(
      leading: ChangeBump(
        value: applied,
        child: applied
            ? const HeroIcon(
                HeroIcons.points,
                size: AppSize.s24,
                color: AppColors.brandDeep,
              )
            : const HeroIcon(
                HeroIcons.points,
                tone: HeroIconTone.gold,
                size: AppSize.s24,
              ),
      ),
      title: applied
          ? 'cart.loyalty_applied'.tr(
              namedArgs: {'points': '${loyalty.pointsApplied}'},
            )
          : 'cart.loyalty_available'.tr(namedArgs: {'points': '$available'}),
      subtitleWidget: applied
          ? CartDiscountAmount(
              kd: loyalty.discountKd,
              style: AppTextStyles.meta,
            )
          : null,
      trailing: HeroTextLink(
        label: applied ? 'cart.loyalty_remove'.tr() : 'cart.loyalty_apply'.tr(),
        navigates: false,
        onTap: busy
            ? null
            : () {
                Haptics.pick();
                final cubit = context.read<CartCubit>();
                if (applied) {
                  cubit.removeLoyalty();
                } else {
                  cubit.applyLoyalty(available);
                }
              },
      ),
      showChevron: false,
      mergeSemantics: false,
    );
  }
}
