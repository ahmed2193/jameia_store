import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';

/// White centred title bar of the help-center pages, with a back arrow.
class SupportAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SupportAppBar({super.key, required this.titleKey});

  /// i18n key of the title.
  final String titleKey;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const HeroIcon(
          HeroIcons.back,
          size: AppSize.s20,
          color: AppColors.primaryText,
        ),
        onPressed: () => context.pop(),
      ),
      title: Text(
        titleKey.tr(),
        style: AppTextStyles.headingLarge.copyWith(
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}
