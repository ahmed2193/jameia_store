import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/assistant_live_turn.dart';
import '../../../domain/entities/assistant_thread.dart';
import '../../cubit/assistant_chat_cubit.dart';
import '../../cubit/assistant_chat_state.dart';
import 'assistant_ended_turn_footer.dart';
import 'assistant_message_footer.dart';
import 'assistant_reply_layout.dart';

/// One assistant reply row — live, stored, failed or stopped — under ONE
/// widget type and key, so when `message_end` swaps the streamed reply for
/// the stored one the row's elements (text, cards, images) are kept and only
/// the caret leaves and the chips arrive. The live reply is read through a
/// narrow selector: a streamed word rebuilds this row only.
class AssistantReplyRow extends StatelessWidget {
  const AssistantReplyRow({
    super.key,
    required this.rowKey,
    this.entry,
    this.isLast = false,
  });

  /// The live turn's key; the stored reply inherits it.
  final String rowKey;

  /// The stored reply or the ended turn; `null` while it streams.
  final AssistantThreadEntry? entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      AssistantChatCubit,
      AssistantChatState,
      AssistantLiveTurn?
    >(
      selector: (state) =>
          state.liveTurn?.key == rowKey ? state.liveTurn : null,
      builder: (context, live) {
        if (live != null) {
          return AssistantReplyLayout(
            richText: live.richText,
            cards: live.cards,
            typing: live.showsTypingIndicator,
            toolName: live.activeToolName,
            streaming: true,
            live: true,
          );
        }
        return switch (entry) {
          AssistantMessageEntry(:final message) => AssistantReplyLayout(
            richText: message.richText,
            cards: message.cards,
            footer: AssistantMessageFooter(message: message),
          ),
          AssistantTurnEntry(:final turn) => AssistantReplyLayout(
            richText: turn.richText,
            cards: turn.cards,
            footer: AssistantEndedTurnFooter(turn: turn, isLast: isLast),
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}
