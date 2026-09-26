import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';

/// "The assistant can make mistakes…" under the starters.
class AssistantDisclaimer extends StatelessWidget {
  const AssistantDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'assistant.disclaimer'.tr(),
      textAlign: TextAlign.center,
      style: AppTextStyles.captionMedium.copyWith(
        color: AppColors.tertiaryText,
      ),
    );
  }
}
