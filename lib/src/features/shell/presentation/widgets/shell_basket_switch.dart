import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_shadows.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/segmented_thumb_track.dart';
import 'shell_basket_segment.dart';

/// The two views of the Cart tab.
enum ShellBasketView { cart, orderHistory }

/// Pill switch between the cart and the order history: one connected track,
/// a white thumb that slides under the chosen view on the app's one thumb
/// track ([SegmentedThumbTrack]: calm spring, RTL-aware, a selection haptic
/// on a change), and the cart's item count on the cart side so it is
/// visible from the history too.
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

  static const List<ShellBasketView> _views = ShellBasketView.values;

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
      child: SegmentedThumbTrack(
        count: _views.length,
        selected: view.index,
        thumb: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: AppShadows.low,
          ),
        ),
        onSelected: (i) => onChanged(_views[i]),
        segmentBuilder: (context, i, select, _) =>
            _views[i] == ShellBasketView.cart
            ? ShellBasketSegment(
                icon: HeroIcons.cart,
                label: 'cart.title'.tr(),
                count: cartCount,
                selected: onCart,
                onTap: select,
              )
            : ShellBasketSegment(
                icon: HeroIcons.receipt,
                label: 'orders.history_title'.tr(),
                selected: !onCart,
                onTap: select,
              ),
      ),
    );
  }
}
