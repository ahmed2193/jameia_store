import 'package:flutter/foundation.dart';

/// Optional `extra` for [Routes.assistant]: open a past conversation
/// ([conversationId], from history) or start with a first question
/// ([initialPrompt], e.g. from a product page). Neither → a new chat.
@immutable
class AssistantChatArgs {
  const AssistantChatArgs({this.conversationId, this.initialPrompt});

  final String? conversationId;
  final String? initialPrompt;
}
