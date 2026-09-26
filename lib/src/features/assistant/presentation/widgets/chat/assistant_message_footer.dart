import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../domain/entities/assistant_message_entity.dart';
import '../../cubit/assistant_chat_cubit.dart';
import '../../cubit/assistant_chat_state.dart';
import 'assistant_message_actions.dart';
import 'assistant_suggestion_chips.dart';

/// Under a stored reply: copy + thumbs, then — on the latest reply only —
/// the suggestion chips (L5: they arrive with `message_end`).
class AssistantMessageFooter extends StatelessWidget {
  const AssistantMessageFooter({super.key, required this.message});

  final AssistantMessageEntity message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message.canRate) AssistantMessageActions(message: message),
        BlocSelector<AssistantChatCubit, AssistantChatState, bool>(
          selector: (state) => state.suggestionsKey == message.key,
          builder: (context, live) => live
              ? Padding(
                  padding: const EdgeInsetsDirectional.only(top: AppSpacing.s4),
                  child: AssistantSuggestionChips(
                    suggestions: message.suggestions,
                    // Only a reply that arrived in this session carries the
                    // live turn's key; history replies sit still.
                    animate: message.clientKey != null,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
