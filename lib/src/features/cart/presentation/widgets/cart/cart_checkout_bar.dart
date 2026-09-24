import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/price_text.dart';
import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_state.dart';

/// Sticky footer: the total and the checkout button. Disabled with the
/// reason while the server says the cart cannot be ordered (minimum order,
/// closed branch, no capacity, unavailable lines) or while taps are still
/// on their way; pending taps are flushed before the checkout opens.
class CartCheckoutBar extends StatelessWidget {
  const CartCheckoutBar({super.key});

  static const double _elevation = 8;

  Future<void> _checkout(BuildContext context) async {
    final synced = await context.read<CartCubit>().prepareCheckout();
    if (synced && context.mounted) await context.push(Routes.checkout);
  }

  String? _reason(CartState state) {
    if (state.isUnsynced) return 'cart.block_offline'.tr();
    return switch (state.cart.checkoutBlock) {
      null || CartCheckoutBlock.empty => null,
      CartCheckoutBlock.lineIssue => 'cart.block_line_issue'.tr(),
      CartCheckoutBlock.belowMinOrder => 'cart.block_min_order'.tr(
        namedArgs: {'amount': Formatters.price(state.cart.totals.shortfallKd)},
      ),
      CartCheckoutBlock.branchClosed => 'cart.block_branch_closed'.tr(),
      CartCheckoutBlock.noCapacity => 'cart.block_no_capacity'.tr(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (previous, current) =>
          previous.cart.totals != current.cart.totals ||
          previous.cart.checkoutBlock != current.cart.checkoutBlock ||
          previous.isUpdating != current.isUpdating ||
          previous.isUnsynced != current.isUnsynced ||
          previous.busyAction != current.busyAction,
      builder: (context, state) {
        final reason = _reason(state);
        final busy = state.busyAction == CartAction.sync;
        return Material(
          color: AppColors.white,
          elevation: _elevation,
          shadowColor: AppColors.divider,
          // Rounded top: the bar reads as a sheet resting on the cards.
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSize.r16),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s16,
                AppSpacing.s12,
                AppSpacing.s16,
                AppSpacing.s12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (reason != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.s8,
                      ),
                      child: Text(
                        reason,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Text(
                        'cart.summary_total'.tr(),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const Spacer(),
                      // The last total the server priced is stale while taps
                      // are still on their way, and this bar is what the
                      // customer reads before paying — so it says "updating"
                      // exactly like the summary above it instead of naming
                      // an amount the order will not have.
                      if (state.isUpdating)
                        Text(
                          'cart.updating'.tr(),
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.tertiaryText,
                          ),
                        )
                      else
                        PriceText(
                          price: state.cart.totals.totalKd,
                          size: AppSize.font18,
                          animate: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  AppButton(
                    label: 'cart.checkout'.tr(),
                    radius: AppRadius.r2,
                    loading: busy,
                    enabled: reason == null && !state.isUpdating && !busy,
                    onPressed: () => _checkout(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
