import 'package:flutter/material.dart';

import '../../../../core/data/jameia/jameia_models.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';

/// Sub-category tab bar (Jameia-styled): scrollable when there are many subs,
/// near-black 3dp indicator, Jameia labels. White background so it reads as a
/// clean shelf below the hero. A fixed row (no longer a SliverPersistentHeader).
class SubTabBar extends StatelessWidget {
  const SubTabBar({
    super.key,
    required this.controller,
    required this.subs,
    this.onTap,
  });

  final TabController controller;
  final List<JameiaSubCategory> subs;

  /// Fires on EVERY tap (including re-tapping the already-active tab) so the host
  /// can dock the tab bar under the hero even when the index doesn't change.
  final ValueChanged<int>? onTap;

  static const double _height = 48;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      color: AppColors.white,
      alignment: AlignmentDirectional.centerStart,
      child: TabBar(
        controller: controller,
        onTap: onTap,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        // Bundle convention: indicator 3dp near-black, NOT yellow.
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r2)),
          borderSide: BorderSide(color: AppColors.tabIndicator, width: 3),
        ),
        dividerColor: AppColors.divider,
        labelColor: AppColors.primaryText,
        unselectedLabelColor: AppColors.secondaryText,
        labelStyle: AppTextStyles.headingMedium.copyWith(
          fontWeight: AppTextStyles.bold,
          fontSize: AppSize.font15,
        ),
        unselectedLabelStyle: AppTextStyles.headingMedium.copyWith(
          fontWeight: AppTextStyles.regular,
          fontSize: AppSize.font15,
        ),
        labelPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12,
        ),
        tabs: [for (final s in subs) Tab(text: s.displayName)],
      ),
    );
  }
}
