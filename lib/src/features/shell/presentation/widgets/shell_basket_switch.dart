import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import 'shell_basket_segment.dart';

/// The two views of the Cart tab.
enum ShellBasketView { cart, orderHistory }

/// Pill switch between the cart and the order history: one connected track,
/// a white thumb that slides under the chosen view (RTL-aware), and the cart's
/// item count on the cart side so it is visible from the history too.
class ShellBasketSwitch extends StatelessWidget {
  const ShellBasketSwitch({
    super.key,
    required this.view,
    required this.cartCount,
    required this.onChanged,
  });

  final ShellBasketView view;
  final int cartCount;
  final ValueChanged<ShellBasketView> onChanged;

  static const double _thumbWidth = 0.5;
  static const double _thumbHeight = 1;

  @override
  Widget build(BuildContext context) {
    final onCart = view == ShellBasketView.cart;
    return Container(
      height: AppSize.s44,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.smallBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: onCart
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            duration: MotionGuard.duration(context, AppMotion.medium),
            curve: MotionGuard.curve(context, AppMotion.signature),
            child: FractionallySizedBox(
              widthFactor: _thumbWidth,
              heightFactor: _thumbHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppShadows.low,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: ShellBasketSegment(
                    icon: JameiaIcons.cart,
                    label: 'cart.title'.tr(),
                    count: cartCount,
                    selected: onCart,
                    onTap: () => onChanged(ShellBasketView.cart),
                  ),
                ),
                Expanded(
                  child: ShellBasketSegment(
                    icon: Icons.receipt_long_rounded,
                    label: 'orders.history_title'.tr(),
                    selected: !onCart,
                    onTap: () => onChanged(ShellBasketView.orderHistory),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
