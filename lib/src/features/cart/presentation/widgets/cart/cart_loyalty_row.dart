import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/domain/entities/cart_loyalty_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../domain/entities/cart_snapshot.dart';
import '../../cubit/cart_cubit.dart';

/// Loyalty points against the cart: "use N points" for a signed-in customer
/// who has some, or the applied points + discount with a remove action.
/// Hidden for guests and customers without points.
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
    if (available <= 0 && !loyalty.isApplied) return const SizedBox.shrink();
    final cubit = context.read<CartCubit>();
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
      ),
      leading: const Icon(
        JameiaIcons.star,
        size: AppSize.s22,
        color: AppColors.primary,
      ),
      title: Text(
        loyalty.isApplied
            ? 'cart.loyalty_applied'.tr(
                namedArgs: {'points': '${loyalty.pointsApplied}'},
              )
            : 'cart.loyalty_available'.tr(namedArgs: {'points': '$available'}),
        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryText),
      ),
      subtitle: loyalty.isApplied
          ? Text(
              '- ${Formatters.price(loyalty.discountKd)}',
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.success,
              ),
            )
          : null,
      trailing: TextButton(
        onPressed: busy
            ? null
            : loyalty.isApplied
            ? cubit.removeLoyalty
            : () => cubit.applyLoyalty(available),
        child: Text(
          loyalty.isApplied
              ? 'cart.loyalty_remove'.tr()
              : 'cart.loyalty_apply'.tr(),
        ),
      ),
    );
  }
}
