import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/cart_snapshot.dart';
import '../../cubit/cart_cubit.dart';

/// Express delivery switch, shown only when the server offers it for this
/// cart (`expressOffered`); the surcharge and ETA come with the offer.
class CartExpressToggle extends StatelessWidget {
  const CartExpressToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final (offered, selected, minutes, surchargeKd) = context
        .select<CartCubit, (bool, bool, int?, double)>(
          (cubit) => (
            cubit.state.cart.expressOffered,
            cubit.state.cart.expressSelected,
            cubit.state.cart.expressEtaMinutes,
            cubit.state.cart.expressSurchargeOfferedKd,
          ),
        );
    final busy = context.select<CartCubit, bool>(
      (cubit) => cubit.state.busyAction == CartAction.express,
    );
    if (!offered) return const SizedBox.shrink();
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
      ),
      value: selected,
      onChanged: busy
          ? null
          : (enabled) => context.read<CartCubit>().setExpress(enabled: enabled),
      activeThumbColor: AppColors.primary,
      title: Text(
        'cart.express_title'.tr(),
        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryText),
      ),
      subtitle: Text(
        'cart.express_subtitle'.tr(
          namedArgs: {
            'minutes': '${minutes ?? 0}',
            'amount': Formatters.price(surchargeKd),
          },
        ),
        style: AppTextStyles.captionLarge.copyWith(
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}
