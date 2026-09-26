import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/assistant_prompt.dart';
import '../entities/assistant_stream_event.dart';
import '../repositories/assistant_repository.dart';

class SendAssistantMessageParams extends Equatable {
  const SendAssistantMessageParams({required this.prompt, this.conversationId});

  /// Already validated (trimmed, 1..2000).
  final AssistantPrompt prompt;

  /// `null` starts a new conversation.
  final String? conversationId;

  @override
  List<Object?> get props => [prompt, conversationId];
}

/// One assistant turn: `POST /v1/assistant/messages`, the reply streamed
/// frame by frame. Listening sends the message ONCE; cancelling the
/// subscription stops the reply (the request is cancelled).
class SendAssistantMessageUseCase
    implements StreamUseCase<AssistantStreamEvent, SendAssistantMessageParams> {
  const SendAssistantMessageUseCase(this._repository);

  final AssistantRepository _repository;

  @override
  Stream<AssistantStreamEvent> call(SendAssistantMessageParams params) =>
      _repository.sendMessage(
        message: params.prompt.text,
        conversationId: params.conversationId,
      );
}
