import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/assistant_message_entity.dart';
import '../../cubit/assistant_chat_cubit.dart';
import 'assistant_copy_sheet.dart';
import 'assistant_thumb_button.dart';

/// The visible action row of a stored reply: copy, helpful, not helpful.
class AssistantMessageActions extends StatelessWidget {
  const AssistantMessageActions({super.key, required this.message});

  final AssistantMessageEntity message;

  @override
  Widget build(BuildContext context) {
    final feedback = message.feedback;
    final copyText = message.richText.plainText;
    void rate(AssistantFeedback tapped) =>
        context.read<AssistantChatCubit>().rate(message.id, tapped);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.s32),
      child: Row(
        children: [
          if (copyText.isNotEmpty)
            AssistantThumbButton(
              icon: Icons.copy_rounded,
              selectedIcon: Icons.copy_rounded,
              label: 'assistant.copy'.tr(),
              selected: false,
              toggles: false,
              color: AppColors.labelGrey,
              onTap: () => AssistantCopySheet.copy(context, copyText),
            ),
          AssistantThumbButton(
            icon: Icons.thumb_up_alt_outlined,
            selectedIcon: Icons.thumb_up_alt,
            label: 'assistant.feedback_up'.tr(),
            selected: feedback == AssistantFeedback.up,
            onTap: () => rate(AssistantFeedback.up),
          ),
          AssistantThumbButton(
            icon: Icons.thumb_down_alt_outlined,
            selectedIcon: Icons.thumb_down_alt,
            label: 'assistant.feedback_down'.tr(),
            selected: feedback == AssistantFeedback.down,
            onTap: () => rate(AssistantFeedback.down),
          ),
        ],
      ),
    );
  }
}
