import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_conversation_entity.dart';
import '../../cubit/assistant_chat_cubit.dart';

/// "Continue your last chat": the open [conversation]'s last line (or its
/// title); a tap opens it again.
class AssistantContinueCard extends StatelessWidget {
  const AssistantContinueCard({super.key, required this.conversation});

  final AssistantConversationEntity conversation;

  @override
  Widget build(BuildContext context) {
    final lastMessage = conversation.previewText;
    final preview = lastMessage.isNotEmpty ? lastMessage : conversation.title;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s16),
      child: Material(
        color: AppColors.brandLightBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: () => context.read<AssistantChatCubit>().resume(),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.s12),
            child: Row(
              children: [
                const Icon(
                  Icons.forum_outlined,
                  size: AppSize.s22,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'assistant.continue_title'.tr(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryText,
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                      if (preview.isNotEmpty)
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.captionLarge.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: AppSize.s22,
                  color: AppColors.primaryDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
