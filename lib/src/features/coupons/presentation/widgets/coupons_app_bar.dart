import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/round_back_button.dart';

/// White bar of the coupon screens: the round back button, the bold
/// start-aligned [title] (fades up once) and an optional [action] at the end.
/// Flat at rest; a soft shadow appears when the list scrolls under it.
class CouponsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CouponsAppBar({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  static const double _height = AppSize.s72;
  static const double _leadingWidth = AppSpacing.s16 + RoundBackButton.diameter;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final trailing = action;
    return AppBar(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.primaryText,
      surfaceTintColor: AppColors.scrimTransparent,
      shadowColor: AppColors.shadowInk10,
      elevation: 0,
      scrolledUnderElevation: AppSize.s4,
      toolbarHeight: _height,
      automaticallyImplyLeading: false,
      leadingWidth: _leadingWidth,
      leading: const Padding(
        padding: EdgeInsetsDirectional.only(start: AppSpacing.s16),
        child: Center(child: RoundBackButton()),
      ),
      centerTitle: false,
      titleSpacing: AppSpacing.s16,
      title: ScrollReveal(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.headingLarge.copyWith(
            fontSize: AppSize.font20,
            fontWeight: AppTextStyles.bold,
            color: AppColors.primaryText,
          ),
        ),
      ),
      actions: [
        if (trailing != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.s16),
            child: Center(child: trailing),
          ),
      ],
    );
  }
}
