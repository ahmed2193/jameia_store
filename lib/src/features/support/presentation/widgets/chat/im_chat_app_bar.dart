import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/navigation/hero_snack_bar.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/core_widgets.dart';

/// Chat title bar: the rider's avatar, name and "Your rider", and a call
/// action (a snack bar offline).
class ImChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ImChatAppBar({super.key, required this.riderName});

  final String riderName;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(
          HeroIcons.back,
          size: AppSize.s20,
          color: AppColors.primaryText,
        ),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Container(
            width: AppSize.s36,
            height: AppSize.s36,
            decoration: const BoxDecoration(
              color: AppColors.smallBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              HeroIcons.delivery,
              size: AppSize.s20,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  riderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                Text.rich(
                  TextSpan(text: 'support.your_rider'.tr()),
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: AppSize.font12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            HeroIcons.phone,
            size: AppSize.s20,
            color: AppColors.primaryText,
          ),
          onPressed: () => showHeroSnackBar(
            context,
            'support.calling'.tr(namedArgs: {'name': riderName}),
          ),
        ),
        const SizedBox(width: AppSpacing.s4),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(AppSize.s1),
        child: ThinDivider(),
      ),
    );
  }
}
