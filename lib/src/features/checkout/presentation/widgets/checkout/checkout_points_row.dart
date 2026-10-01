import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_assets.dart';
import '../../../../../core/domain/entities/cart_loyalty_entity.dart';
import '../../../../../core/domain/entities/loyalty_program.dart';
import '../../../../../core/motion/change_bump.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_svg_glyph.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_list_row.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_coupons_row.dart';

/// "Points" in the savings card (customers only): "Use N points · worth
/// KD x" with a switch, or "N points · saved KD x" once applied. It shows
/// when points are applied or the store's one redeem rule says the balance
/// may be spent on this basket ([LoyaltyProgram.canRedeemOn]: not once the
/// coupon and the offers cover the goods); switching on sends
/// [LoyaltyProgram.pointsToRedeem] (enough for what the goods still cost,
/// at least the minimum, never more than the balance) and "worth" is capped
/// at that cost. A balance under the store's minimum gets a plain line
/// "You have N points · redeem from M", with no switch.
///
/// The switch rests while any cart action runs. A refusal is reported by
/// the cart view under the page (no snack here); the star bumps when the
/// points land or leave.
class CheckoutPointsRow extends StatelessWidget {
  const CheckoutPointsRow({super.key});

  static const double _iconSize = CheckoutCouponsRow.discSize;

  /// The hairline starts at the text column, like the rows' own.
  static const double _textStart =
      HeroListRow.denseInset + _iconSize + HeroListRow.denseGap;

  @override
  Widget build(BuildContext context) {
    final balance = context.select<AuthSessionCubit, int?>(
      (session) => session.state.customer?.loyaltyPoints,
    );
    final program = context.select<CheckoutCubit, LoyaltyProgram>(
      (cubit) => cubit.state.rules.loyalty,
    );
    final loyalty = context.select<CartCubit, CartLoyaltyEntity>(
      (cubit) => cubit.state.cart.loyalty,
    );
    final busy = context.select<CartCubit, bool>((cubit) => cubit.state.isBusy);
    final points = balance ?? 0;
    final redeem = context
        .select<CartCubit, ({bool usable, int toRedeem, double worthKd})>((
          cubit,
        ) {
          final totals = cubit.state.cart.totals;
          return (
            usable: program.canRedeemOn(points, totals),
            toRedeem: program.pointsToRedeem(points, totals),
            worthKd: program.worthKd(points, totals),
          );
        });
    final applied = loyalty.isApplied;
    final redeemable = balance != null && (applied || redeem.usable);
    final belowMinimum =
        balance != null && !redeemable && program.isBelowMinimum(points);
    final subtitle = applied
        ? 'checkout.savings_points_applied'.tr(
            namedArgs: {
              'points': '${loyalty.pointsApplied}',
              'amount': Formatters.price(loyalty.discountKd),
            },
          )
        : redeemable
        ? 'checkout.savings_points_use'.tr(
            namedArgs: {
              'points': '${redeem.toRedeem}',
              'amount': Formatters.price(redeem.worthKd),
            },
          )
        : 'checkout.savings_points_min'.tr(
            namedArgs: {
              'points': '$points',
              'min': '${program.minRedeemPoints}',
            },
          );
    void toggle(bool on) {
      Haptics.pick();
      final cart = context.read<CartCubit>();
      if (on) {
        cart.applyLoyalty(redeem.toRedeem);
      } else {
        cart.removeLoyalty();
      }
    }

    final visible = redeemable || belowMinimum;
    return CollapseReveal(
      visible: visible,
      child: !visible
          ? const SizedBox.shrink()
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(
                  height: AppSize.s1,
                  thickness: AppSize.s1,
                  indent: _textStart,
                  color: AppColors.voucherTanFaint,
                ),
                HeroListRow(
                  dense: true,
                  leading: ChangeBump(
                    value: applied,
                    child: const HeroSvgGlyph.art(
                      HeroAssets.checkoutPoints,
                      size: _iconSize,
                    ),
                  ),
                  title: 'checkout.savings_points'.tr(),
                  subtitle: subtitle,
                  trailing: redeemable
                      ? Switch.adaptive(
                          value: applied,
                          onChanged: busy ? null : toggle,
                          activeTrackColor: AppColors.primary,
                        )
                      : null,
                  showChevron: false,
                  mergeSemantics: false,
                ),
              ],
            ),
    );
  }
}
