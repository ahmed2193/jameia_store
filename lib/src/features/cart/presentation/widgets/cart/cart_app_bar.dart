import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../cubit/cart_cubit.dart';
import 'cart_clear_dialog.dart';

/// Cart title plus "clear" while the cart has lines.
class CartAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CartAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canClear = context.select<CartCubit, bool>(
      (cubit) => cubit.state.cart.lines.isNotEmpty && !cubit.state.isBusy,
    );
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      title: Text(
        'cart.title'.tr(),
        style: AppTextStyles.displaySmall.copyWith(
          fontWeight: AppTextStyles.medium,
        ),
      ),
      actions: [
        if (canClear)
          IconButton(
            tooltip: 'cart.clear'.tr(),
            onPressed: () => CartClearDialog.confirmAndClear(context),
            icon: const Icon(JameiaIcons.delete, color: AppColors.primaryText),
          ),
      ],
    );
  }
}
