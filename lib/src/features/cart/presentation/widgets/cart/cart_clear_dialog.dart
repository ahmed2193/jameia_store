import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../cubit/cart_cubit.dart';

/// "Clear the cart?" through the shared confirmation dialog: the red
/// "Clear" confirms (the destructive colour lives here, not on the link that
/// opens it).
abstract final class CartClearDialog {
  /// Asks, then clears the cart on a yes. A clear that went through is
  /// said with an "Undo" (docs/motion B3-03) that puts every line back in
  /// one request — read before the await: once cleared, the caller is gone
  /// (the cart turns into its empty state).
  static Future<void> confirmAndClear(BuildContext context) async {
    final confirmed = await showHeroConfirmDialog(
      context,
      title: 'cart.clear_confirm_title'.tr(),
      message: 'cart.clear_confirm_body'.tr(),
      icon: HeroIcons.trash,
      confirmLabel: 'cart.clear_confirm_action'.tr(),
      cancelLabel: 'cart.cancel'.tr(),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
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
}
