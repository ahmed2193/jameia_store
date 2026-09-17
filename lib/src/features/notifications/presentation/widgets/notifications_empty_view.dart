import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';

/// Nothing in the inbox yet: title + hint about what will land here.
class NotificationsEmptyView extends StatelessWidget {
  const NotificationsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PopScale.onMount(
              child: Icon(
                Icons.notifications_none_rounded,
                size: AppSize.s56,
                color: AppColors.disabledText,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'notifications.empty_title'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(
              'notifications.empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
