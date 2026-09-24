import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../cubit/cart_cubit.dart';

/// "Clear the cart?" — pops `true` to confirm.
class CartClearDialog extends StatelessWidget {
  const CartClearDialog({super.key});

  /// Asks, then clears the cart on a yes.
  static Future<void> confirmAndClear(BuildContext context) async {
    final confirmed = await showJameiaDialog<bool>(
      context,
      barrierLabel: 'cart.clear'.tr(),
      pageBuilder: (_) => const CartClearDialog(),
    );
    if (confirmed == true && context.mounted) {
      await context.read<CartCubit>().clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('cart.clear_confirm_title'.tr()),
      content: Text('cart.clear_confirm_body'.tr()),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: Text('cart.cancel'.tr()),
        ),
        TextButton(
          onPressed: () => context.pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text('cart.clear_confirm_action'.tr()),
        ),
      ],
    );
  }
}
