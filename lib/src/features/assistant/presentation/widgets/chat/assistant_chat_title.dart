import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../cubit/assistant_chat_cubit.dart';
import 'assistant_chat_header_avatar.dart';

/// The status line under the title.
enum _Status { ready, typing, support }

/// Avatar ([AssistantChatHeaderAvatar]: its moods follow the chat),
/// "Hero Assistant" and a status line that flips ([FlipValue]) between
/// "Products, offers…", "Typing…" while a reply streams and "With support"
/// once a person has the chat. (Screen readers hear the reply through the
/// page's announcements, not through this title.)
class AssistantChatTitle extends StatelessWidget {
  const AssistantChatTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AssistantChatCubit, _Status>((cubit) {
      final state = cubit.state;
      if (state.isStreaming) return _Status.typing;
      if (state.thread.isHandedOff) return _Status.support;
      return _Status.ready;
    });
    final typing = status == _Status.typing;
    return Row(
      children: [
        const AssistantChatHeaderAvatar(),
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
                flipKey: status,
                child: Text(
                  switch (status) {
                    _Status.typing => 'assistant.subtitle_typing',
                    _Status.support => 'assistant.status_handed_off',
                    _Status.ready => 'assistant.subtitle_ready',
                  }.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: typing
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
