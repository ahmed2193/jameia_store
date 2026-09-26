import 'package:equatable/equatable.dart';

import 'assistant_block.dart';
import 'assistant_message_entity.dart';

/// One frame of a `POST /v1/assistant/messages` reply, in wire order:
/// started → userMessage → (textDelta | toolStarted | toolFinished | block)*
/// → completed | failed.
sealed class AssistantStreamEvent extends Equatable {
  const AssistantStreamEvent();

  /// `completed` / `failed`: nothing follows.
  bool get isTerminal => false;
}

/// `message_start`: the conversation the reply belongs to. A different id
/// than the thread's means the old thread was closed and a new one began.
final class AssistantStreamStarted extends AssistantStreamEvent {
  const AssistantStreamStarted({required this.conversationId});

  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// `user_message`: the customer's message as the server stored it.
final class AssistantStreamUserMessage extends AssistantStreamEvent {
  const AssistantStreamUserMessage({
    required this.conversationId,
    required this.message,
  });

  final String conversationId;
  final AssistantMessageEntity message;

  @override
  List<Object?> get props => [conversationId, message];
}

/// `text_delta`: the next word(s) of the reply (word-sized, ~10 ms apart —
/// L3). The cubit coalesces them before they reach the state.
final class AssistantStreamTextDelta extends AssistantStreamEvent {
  const AssistantStreamTextDelta({required this.delta});

  final String delta;

  @override
  List<Object?> get props => [delta];
}

/// `tool_start`: the assistant is looking something up.
final class AssistantStreamToolStarted extends AssistantStreamEvent {
  const AssistantStreamToolStarted({required this.name, required this.callId});

  final String name;
  final String callId;

  @override
  List<Object?> get props => [name, callId];
}

/// `tool_end`. [ok] `false` is the model's problem, not the customer's: the
/// UI stays silent about it.
final class AssistantStreamToolFinished extends AssistantStreamEvent {
  const AssistantStreamToolFinished({
    required this.name,
    required this.callId,
    this.ok = true,
  });

  final String name;
  final String callId;
  final bool ok;

  @override
  List<Object?> get props => [name, callId, ok];
}

/// `block`: a card for the reply in progress (they stream BEFORE the text —
/// L4).
final class AssistantStreamBlock extends AssistantStreamEvent {
  const AssistantStreamBlock({required this.block});

  final AssistantBlock block;

  @override
  List<Object?> get props => [block];
}

/// `message_end`: the stored reply, the truth that replaces the live turn.
final class AssistantStreamCompleted extends AssistantStreamEvent {
  const AssistantStreamCompleted({
    required this.conversationId,
    required this.message,
  });

  final String conversationId;
  final AssistantMessageEntity message;

  @override
  bool get isTerminal => true;

  @override
  List<Object?> get props => [conversationId, message];
}

/// `error`: the reply failed server-side; what streamed so far stays. [code]
/// is a backend code (`AssistantErrorCode`), [message] is shown as sent.
final class AssistantStreamFailed extends AssistantStreamEvent {
  const AssistantStreamFailed({required this.code, this.message = ''});

  final String code;
  final String message;

  @override
  bool get isTerminal => true;

  @override
  List<Object?> get props => [code, message];
}
