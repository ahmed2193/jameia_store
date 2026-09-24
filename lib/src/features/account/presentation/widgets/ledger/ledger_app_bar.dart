import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/responsive/app_size.dart';

/// White centered-title bar with the Jameia back glyph for the wallet and
/// points screens (same chrome as the other Mine sub-pages).
class LedgerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LedgerAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.primaryText,
      elevation: 0,
      scrolledUnderElevation: AppSize.s0_5,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(JameiaIcons.back, size: AppSize.s20),
        onPressed: () => context.pop(),
      ),
      title: Text(
        title,
        style: AppTextStyles.headingLarge.copyWith(
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}
