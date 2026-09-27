import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_coupon_entity.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/pop_switcher.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/jameia_text_link.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import 'checkout_applied_mark.dart';
import 'checkout_ticket_card.dart';
import 'checkout_ticket_headline.dart';
import 'checkout_vouchers_header.dart';

/// "Your coupon": the code on the cart as a ticket — what it saves ("KD x
/// saved", or that it saves nothing on this basket), "✓ Applied" (popping
/// in for a new code) and "Remove" (`DELETE /v1/cart/coupon`; resting
/// while any cart action runs). Opens and folds with the coupon.
class CheckoutAppliedCouponCard extends StatelessWidget {
  const CheckoutAppliedCouponCard({super.key});

  @override
  Widget build(BuildContext context) {
    final coupon = context.select<CartCubit, CartCouponEntity?>(
      (cubit) => cubit.state.cart.coupon,
    );
    final busy = context.select<CartCubit, bool>((cubit) => cubit.state.isBusy);
    return CollapseReveal(
      visible: coupon != null,
      child: coupon == null
          ? const SizedBox.shrink()
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CheckoutVouchersHeader(
                  title: 'checkout.coupon_card_title'.tr(),
                ),
                CheckoutTicketCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CheckoutTicketHeadline(text: coupon.code),
                      const SizedBox(height: AppSpacing.s6),
                      Text(
                        coupon.discountFils > 0
                            ? 'checkout.coupon_saved'.tr(
                                namedArgs: {
                                  'amount': Formatters.price(coupon.discountKd),
                                },
                              )
                            : 'checkout.coupon_no_saving'.tr(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: coupon.discountFils > 0
                              ? AppColors.errorDeep
                              : AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: PopSwitcher(
                                stateKey: coupon.code,
                                alignment: AlignmentDirectional.centerStart,
                                child: const CheckoutAppliedMark(),
                              ),
                            ),
                          ),
                          JameiaTextLink(
                            label: 'checkout.remove'.tr(),
                            navigates: false,
                            onTap: busy
                                ? null
                                : () {
                                    Haptics.selection();
                                    context.read<CartCubit>().removeCoupon();
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
