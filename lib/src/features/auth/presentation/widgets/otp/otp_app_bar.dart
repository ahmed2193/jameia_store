import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/round_back_button.dart';
import '../auth_back_button.dart';

/// White, flat bar of the code step: just the round back button (when there
/// is a phone step to return to).
class OtpAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OtpAppBar({super.key});

  static const double _height = AppSize.s64;
  static const double _leadingWidth = AppSpacing.s16 + RoundBackButton.diameter;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.scrimTransparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: _height,
      automaticallyImplyLeading: false,
      leadingWidth: _leadingWidth,
      leading: const Padding(
        padding: EdgeInsetsDirectional.only(start: AppSpacing.s16),
        child: Center(child: AuthBackButton()),
      ),
    );
  }
}
