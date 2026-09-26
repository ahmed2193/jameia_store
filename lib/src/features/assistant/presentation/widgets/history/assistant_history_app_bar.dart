import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// "Chat history".
class AssistantHistoryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AssistantHistoryAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      title: Text('assistant.history'.tr(), style: AppTextStyles.headingMedium),
    );
  }
}
