import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/price_text.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../cubit/checkout_cubit.dart';

/// Sticky footer: the total and "Place order". One tap places once; the
/// button waits while the cart still syncs or a destination is being
/// selected.
class CheckoutPlaceOrderBar extends StatelessWidget {
  const CheckoutPlaceOrderBar({super.key});

  static const double _elevation = 8;

  /// Stands in for a total the server has not quoted yet — see [CheckoutSummary].
  static const String _unquoted = '—';

  @override
  Widget build(BuildContext context) {
    final canPlace = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.canPlace,
    );
    final placing = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.isPlacing,
    );
    final cartReady = context.select<CartCubit, bool>(
      (cubit) =>
          !cubit.state.isUpdating &&
          !cubit.state.isBusy &&
          cubit.state.cart.canCheckout,
    );
    final totalKd = context.select<CartCubit, double>(
      (cubit) => cubit.state.cart.totals.totalKd,
    );
    final quoted = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.selection != null,
    );
    return Material(
      color: AppColors.white,
      elevation: _elevation,
      shadowColor: AppColors.divider,
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
              Row(
                children: [
                  Text(
                    'checkout.summary_total'.tr(),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const Spacer(),
                  if (quoted)
                    PriceText(
                      price: totalKd,
                      size: AppSize.font18,
                      animate: true,
                    )
                  else
                    Text(
                      _unquoted,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              AppButton(
                label: placing
                    ? 'checkout.placing'.tr()
                    : 'checkout.place_order'.tr(),
                radius: AppRadius.r2,
                loading: placing,
                enabled: canPlace && cartReady,
                onPressed: () => context.read<CheckoutCubit>().placeOrder(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
