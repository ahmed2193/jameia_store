import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../domain/entities/assistant_history_rows.dart';

/// "Today", "Yesterday", "This week" or "Earlier" above its conversations.
class AssistantHistoryHeader extends StatelessWidget {
  const AssistantHistoryHeader({super.key, required this.bucket});

  final AssistantHistoryBucket bucket;

  @override
  Widget build(BuildContext context) {
    final key = switch (bucket) {
      AssistantHistoryBucket.today => 'assistant.history_today',
      AssistantHistoryBucket.yesterday => 'assistant.history_yesterday',
      AssistantHistoryBucket.thisWeek => 'assistant.history_this_week',
      AssistantHistoryBucket.earlier => 'assistant.history_earlier',
    };
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s4,
      ),
      child: Semantics(
        header: true,
        child: Text(
          key.tr(),
          style: AppTextStyles.captionLarge.copyWith(
            color: AppColors.secondaryText,
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
    );
  }
}
