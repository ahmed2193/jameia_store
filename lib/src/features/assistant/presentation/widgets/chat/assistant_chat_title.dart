import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/assistant_chat_cubit.dart';
import 'assistant_avatar.dart';

/// Avatar, "Jm3eia Assistant" and a status line that flips between "Products,
/// offers…" and "Typing…" while a reply streams. (Screen readers hear the
/// reply through the page's announcements, not through this title.)
class AssistantChatTitle extends StatelessWidget {
  const AssistantChatTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final streaming = context.select<AssistantChatCubit, bool>(
      (cubit) => cubit.state.isStreaming,
    );
    return Row(
      children: [
        const AssistantAvatar(size: AppSize.s32, alive: true),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'assistant.title'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSmall,
                ),
              ),
              FlipValue(
                flipKey: streaming,
                child: Text(
                  (streaming
                          ? 'assistant.subtitle_typing'
                          : 'assistant.subtitle_ready')
                      .tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: streaming
                        ? AppColors.primaryDark
                        : AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
