import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/responsive/app_size.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';

class OrdersTabBar extends StatelessWidget implements PreferredSizeWidget {
  const OrdersTabBar({super.key});

  // Bundle: tab bar height 50dp (f6204a: height 50dp)
  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: false,
      // Bundle: indicator height 3dp, background #0D0D0D (near-black, NOT yellow)
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: const UnderlineTabIndicator(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r2)),
        borderSide: BorderSide(
          // af548e: background #0D0D0D, 3dp height
          color: AppColors.tabIndicator,
          width: 3,
        ),
      ),
      dividerColor: AppColors.divider,
      // Bundle: active tab Jameia-Bold 16dp #000000 (gf1530); inactive Jameia-Regular 16dp #000000 (c7bd38)
      labelColor: AppColors.primaryText,
      unselectedLabelColor: AppColors.secondaryText,
      labelStyle: AppTextStyles.headingMedium.copyWith(
        fontWeight: AppTextStyles.bold,
        fontSize: AppSize.font16,
      ),
      unselectedLabelStyle: AppTextStyles.headingMedium.copyWith(
        fontWeight: AppTextStyles.regular,
      ),
      tabs: [
        Tab(text: 'orders.tab_in_progress'.tr()),
        Tab(text: 'orders.tab_history'.tr()),
      ],
    );
  }
}
