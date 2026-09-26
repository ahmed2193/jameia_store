import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/assistant_prompt.dart';

/// "1850 / 2000" above the field once a message nears the limit; red past
/// it. Counts characters as the server does (code points).
class AssistantCharCounter extends StatelessWidget {
  const AssistantCharCounter({super.key, required this.length});

  final int length;

  @override
  Widget build(BuildContext context) {
    final over = length > AssistantPrompt.maxLength;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        bottom: AppSpacing.s4,
        end: AppSpacing.s4,
      ),
      child: Semantics(
        liveRegion: over,
        child: Text(
          'assistant.char_count'.tr(
            namedArgs: {
              // Isolated: "1850 / 2000" must not flip to "2000 / 1850" in
              // Arabic.
              'count': Formatters.isolate('$length'),
              'max': Formatters.isolate('${AssistantPrompt.maxLength}'),
            },
          ),
          textAlign: TextAlign.end,
          style: AppTextStyles.captionMedium.copyWith(
            color: over ? AppColors.error : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }
}
