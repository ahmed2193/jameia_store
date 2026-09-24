import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/domain/entities/cart_coupon_entity.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/cart_snapshot.dart';
import '../../cubit/cart_cubit.dart';
import 'cart_coupon_sheet.dart';

/// The applied coupon (code + discount, removable) or the entry to add one.
class CartCouponRow extends StatelessWidget {
  const CartCouponRow({super.key});

  void _open(BuildContext context) => showJameiaBottomSheet<void>(
    context,
    isScrollControlled: true,
    builder: (_) => const CartCouponSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final coupon = context.select<CartCubit, CartCouponEntity?>(
      (cubit) => cubit.state.cart.coupon,
    );
    final busy = context.select<CartCubit, bool>(
      (cubit) => cubit.state.busyAction == CartAction.coupon,
    );
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
      ),
      // No coupon glyph in wm_c_iconfont — its 0xe014 is the WORD 賞 — so this
      // is the same Material ticket the Mine menu and the coupon notification
      // already use.
      leading: const Icon(
        Icons.confirmation_number_outlined,
        size: AppSize.s22,
        color: AppColors.primary,
      ),
      title: Text(
        coupon == null
            ? 'cart.coupon_add'.tr()
            : 'cart.coupon_applied'.tr(namedArgs: {'code': coupon.code}),
        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primaryText),
      ),
      subtitle: coupon == null
          ? null
          : Text(
              '- ${Formatters.price(coupon.discountKd)}',
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.success,
              ),
            ),
      trailing: coupon == null
          ? const Icon(Icons.chevron_right, color: AppColors.tertiaryText)
          : IconButton(
              tooltip: 'cart.coupon_remove'.tr(),
              onPressed: busy
                  ? null
                  : () => context.read<CartCubit>().removeCoupon(),
              icon: const Icon(Icons.close, size: AppSize.s20),
            ),
      onTap: coupon == null && !busy ? () => _open(context) : null,
    );
  }
}
