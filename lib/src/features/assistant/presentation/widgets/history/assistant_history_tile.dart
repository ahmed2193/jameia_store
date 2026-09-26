import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/tag_chip.dart';
import '../../../domain/entities/assistant_conversation_entity.dart';
import '../../../domain/entities/assistant_text_direction.dart';

/// One past conversation: title, last line (2 lines), when, and a chip for a
/// chat that is with support or ended. A tap returns its id to the chat.
class AssistantHistoryTile extends StatelessWidget {
  const AssistantHistoryTile({super.key, required this.conversation});

  final AssistantConversationEntity conversation;

  @override
  Widget build(BuildContext context) {
    final at = conversation.lastMessageAt ?? conversation.createdAt;
    final statusKey = switch (conversation.status) {
      AssistantConversationStatus.handedOff => 'assistant.status_handed_off',
      AssistantConversationStatus.closed => 'assistant.status_closed',
      AssistantConversationStatus.active ||
      AssistantConversationStatus.other => null,
    };
    final caption = AppTextStyles.captionLarge.copyWith(
      color: AppColors.secondaryText,
    );
    final preview = conversation.previewText;
    final title = conversation.title.isEmpty
        ? 'assistant.title'.tr()
        : conversation.title;
    // A title / last line reads in its own direction (an English question
    // in the Arabic app), not the app's.
    TextDirection? directionOf(String text) =>
        switch (AssistantTextDirection.isRtl(text)) {
          true => TextDirection.rtl,
          false => TextDirection.ltr,
          null => null,
        };
    return InkWell(
      onTap: () => context.pop(conversation.id),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    textDirection: directionOf(title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                ),
                if (statusKey != null) ...[
                  const SizedBox(width: AppSpacing.s8),
                  TagChip(
                    label: statusKey.tr(),
                    bg: AppColors.smallBackground,
                    fg: AppColors.secondaryText,
                  ),
                ],
              ],
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                preview,
                textDirection: directionOf(preview),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: caption,
              ),
            ],
            if (at != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                Formatters.dateTime(context.locale.languageCode, at),
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.tertiaryText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
