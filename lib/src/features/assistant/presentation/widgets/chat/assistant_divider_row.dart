import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';

/// "New chat started": the server closed the thread and the conversation
/// continues in a new one from here.
class AssistantDividerRow extends StatelessWidget {
  const AssistantDividerRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s8),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: AppColors.divider, height: AppSize.s1),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s8,
            ),
            child: Text(
              'assistant.new_chat_started'.tr(),
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.labelGrey,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: AppColors.divider, height: AppSize.s1),
          ),
        ],
      ),
    );
  }
}
