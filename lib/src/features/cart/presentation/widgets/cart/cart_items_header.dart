import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/cart_cubit.dart';
import 'cart_clear_dialog.dart';

/// "3 items · Clear cart" over the lines. The Cart tab has no app bar of its
/// own (the tab's switch sits there), so this row carries the clear action.
class CartItemsHeader extends StatelessWidget {
  const CartItemsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final (count, canClear) = context.select<CartCubit, (int, bool)>(
      (cubit) => (
        cubit.state.totalQty,
        cubit.state.cart.lines.isNotEmpty && !cubit.state.isBusy,
      ),
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            'cart.items_count'.tr(namedArgs: {'count': '$count'}),
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.primaryText,
              fontWeight: AppTextStyles.bold,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: canClear
              ? () => CartClearDialog.confirmAndClear(context)
              : null,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          icon: const Icon(JameiaIcons.delete, size: AppSize.s18),
          label: Text('cart.clear'.tr()),
        ),
      ],
    );
  }
}
