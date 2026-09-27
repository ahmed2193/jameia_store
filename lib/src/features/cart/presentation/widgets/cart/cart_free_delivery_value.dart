import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../store_mode/presentation/cubit/pro_status_cubit.dart';

/// The delivery row's value when the server made delivery free: "Free", and
/// for a Hero Pro member whose plan includes free delivery the violet
/// "pro" tag before it (it pops in when the membership starts). Read as one
/// phrase — "Free delivery with Hero Pro" — by screen readers.
class CartFreeDeliveryValue extends StatelessWidget {
  const CartFreeDeliveryValue({super.key});

  static const double _tagRadius = AppSize.r4;

  @override
  Widget build(BuildContext context) {
    final byPro = context.select<ProStatusCubit, bool>(
      (status) => status.state.memberFreeDelivery,
    );
    final free = Text(
      'cart.summary_free'.tr(),
      style: const TextStyle(color: AppColors.brandDeep),
    );
    if (!byPro) return free;
    return Semantics(
      label: 'cart.pro_free_delivery'.tr(),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopScale.onMount(
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s5,
                vertical: AppSpacing.s1,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentViolet,
                borderRadius: BorderRadius.circular(_tagRadius),
              ),
              child: Text(
                'cart.pro_tag'.tr(),
                style: AppTextStyles.captionLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: AppTextStyles.bold,
                  height: AppSize.lh1_2,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s6),
          Flexible(child: free),
        ],
      ),
    );
  }
}
