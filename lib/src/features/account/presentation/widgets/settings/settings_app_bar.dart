import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/round_back_button.dart';

/// Title bar of the Settings, About and Delivery-code screens: the round back
/// button and a start-aligned title that fades up once, on the page colour.
/// Flat at rest; a soft shadow appears when the content scrolls under it.
class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsAppBar({super.key, required this.title});

  static const double _height = AppSize.s72;
  static const double _leadingWidth = AppSpacing.s16 + RoundBackButton.diameter;

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.mediumBackground,
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
    );
  }
}
