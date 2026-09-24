import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';

/// Plain white app bar of the marketing pages (offers, CMS pages).
class MarketingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MarketingAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.headingMedium.copyWith(
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}
