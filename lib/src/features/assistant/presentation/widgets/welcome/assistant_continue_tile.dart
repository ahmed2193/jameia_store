import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/collapse_reveal.dart';
import '../../../domain/entities/assistant_conversation_entity.dart';
import '../../cubit/assistant_chat_cubit.dart';
import 'assistant_continue_card.dart';

/// "Continue your last chat" ([AssistantContinueCard]) when the customer
/// has an open conversation; nothing otherwise. It opens when the answer
/// comes in (height `medium`, fade — docs/motion §9.6 §2.12) instead of
/// pushing the starters down in one frame.
class AssistantContinueTile extends StatelessWidget {
  const AssistantContinueTile({super.key});

  @override
  Widget build(BuildContext context) {
    final conversation = context
        .select<AssistantChatCubit, AssistantConversationEntity?>(
          (cubit) => cubit.state.resumable,
        );
    return CollapseReveal(
      visible: conversation != null,
      child: conversation == null
          ? const SizedBox.shrink()
          : AssistantContinueCard(conversation: conversation),
    );
  }
}
