import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/cart_cubit.dart';

/// "Clear the cart?" — pops `true` to confirm. White, 16 dp corners, ink
/// "Cancel" and a red "Clear" (the destructive colour lives here, not on
/// the link that opens it).
class CartClearDialog extends StatelessWidget {
  const CartClearDialog({super.key});

  static const ShapeBorder _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.media)),
  );
  static const Size _minActionSize = Size(0, AppSize.s44);

  /// Asks, then clears the cart on a yes. A clear that went through is
  /// said with an "Undo" (docs/motion B3-03) that puts every line back in
  /// one request — read before the await: once cleared, this widget is
  /// gone (the cart turns into its empty state).
  static Future<void> confirmAndClear(BuildContext context) async {
    final confirmed = await showHeroDialog<bool>(
      context,
      barrierLabel: 'cart.clear'.tr(),
      pageBuilder: (_) => const CartClearDialog(),
    );
    if (confirmed != true || !context.mounted) return;
    final cart = context.read<CartCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final lines = cart.state.cart.restoreItems;
    if (!await cart.clear() || lines.isEmpty) return;
    showHeroSnackBarOn(
      messenger,
      'cart.cleared'.tr(),
      tone: HeroSnackTone.success,
      actionLabel: 'core.undo'.tr(),
      onAction: () => cart.addItems(lines),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      shape: _shape,
      titleTextStyle: AppTextStyles.groupTitle,
      contentTextStyle: AppTextStyles.itemTitle.copyWith(
        color: AppColors.secondaryText,
      ),
      actionsPadding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        0,
        AppSpacing.s16,
        AppSpacing.s16,
      ),
      title: Text('cart.clear_confirm_title'.tr()),
      content: Text('cart.clear_confirm_body'.tr()),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryText,
            textStyle: AppTextStyles.label,
            minimumSize: _minActionSize,
          ),
          child: Text('cart.cancel'.tr()),
        ),
        TextButton(
          onPressed: () {
            Haptics.destructive();
            context.pop(true);
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.errorDeep,
            textStyle: AppTextStyles.label,
            minimumSize: _minActionSize,
          ),
          child: Text('cart.clear_confirm_action'.tr()),
        ),
      ],
    );
  }
}
