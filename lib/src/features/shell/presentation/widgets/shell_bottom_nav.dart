import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import 'shell_nav_item.dart';

/// Home / Search / Cart / Mine. The Cart destination carries the cart's item
/// count and the fly-to-cart target key.
class ShellBottomNav extends StatelessWidget {
  const ShellBottomNav({
    super.key,
    required this.index,
    required this.cartIconKey,
    required this.onTap,
  });

  /// Tab positions, shared with the shell.
  static const int homeTab = 0;
  static const int searchTab = 1;
  static const int cartTab = 2;
  static const int mineTab = 3;

  final int index;
  final GlobalKey cartIconKey;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: AppSize.s0_5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSize.s56,
          child: Row(
            children: [
              Expanded(
                child: ShellNavItem(
                  icon: Icons.home_rounded,
                  label: 'tab_home'.tr(),
                  selected: index == homeTab,
                  onTap: () => onTap(homeTab),
                ),
              ),
              Expanded(
                child: ShellNavItem(
                  icon: Icons.search_rounded,
                  label: 'tab_search'.tr(),
                  selected: index == searchTab,
                  onTap: () => onTap(searchTab),
                ),
              ),
              // Only this item follows the cart, and only its count.
              Expanded(
                child: BlocSelector<CartCubit, CartState, int>(
                  selector: (state) => state.totalQty,
                  builder: (context, count) => ShellNavItem(
                    icon: JameiaIcons.cart,
                    label: 'tab_cart'.tr(),
                    selected: index == cartTab,
                    badge: count,
                    iconKey: cartIconKey,
                    onTap: () => onTap(cartTab),
                  ),
                ),
              ),
              Expanded(
                child: ShellNavItem(
                  icon: Icons.person_rounded,
                  label: 'tab_mine'.tr(),
                  selected: index == mineTab,
                  onTap: () => onTap(mineTab),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
