import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../domain/entities/assistant_message_entity.dart';
import '../../cubit/assistant_chat_cubit.dart';
import 'assistant_copy_sheet.dart';
import 'assistant_thanks_note.dart';
import 'assistant_thumb_button.dart';

/// The visible action row of a stored reply: copy, helpful, not helpful —
/// and, after a rating, a short "Thanks!" beside them.
class AssistantMessageActions extends StatefulWidget {
  const AssistantMessageActions({super.key, required this.message});

  final AssistantMessageEntity message;

  @override
  State<AssistantMessageActions> createState() =>
      _AssistantMessageActionsState();
}

class _AssistantMessageActionsState extends State<AssistantMessageActions> {
  int _thanks = 0;

  void _rate(AssistantFeedback tapped) {
    final message = widget.message;
    // A rating (not an un-rate) thanks the customer where they tapped.
    if (message.feedback != tapped) setState(() => _thanks++);
    context.read<AssistantChatCubit>().rate(message.id, tapped);
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final feedback = message.feedback;
    final copyText = message.richText.plainText;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.s32),
      child: Row(
        children: [
          if (copyText.isNotEmpty)
            AssistantThumbButton(
              icon: HeroIcons.copy,
              selectedIcon: HeroIcons.copy,
              label: 'assistant.copy'.tr(),
              selected: false,
              toggles: false,
              color: AppColors.labelGrey,
              onTap: () => AssistantCopySheet.copy(context, copyText),
            ),
          AssistantThumbButton(
            icon: HeroIcons.thumbUp,
            selectedIcon: HeroIcons.thumbUp,
            label: 'assistant.feedback_up'.tr(),
            selected: feedback == AssistantFeedback.up,
            onTap: () => _rate(AssistantFeedback.up),
          ),
          AssistantThumbButton(
            icon: HeroIcons.thumbDown,
            selectedIcon: HeroIcons.thumbDown,
            label: 'assistant.feedback_down'.tr(),
            selected: feedback == AssistantFeedback.down,
            onTap: () => _rate(AssistantFeedback.down),
          ),
          Flexible(child: AssistantThanksNote(showKey: _thanks)),
        ],
      ),
    );
  }
}
