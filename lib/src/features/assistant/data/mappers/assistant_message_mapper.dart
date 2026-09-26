import '../../domain/entities/assistant_action_result.dart';
import '../../domain/entities/assistant_availability.dart';
import '../../domain/entities/assistant_block.dart';
import '../../domain/entities/assistant_conversation_entity.dart';
import '../../domain/entities/assistant_conversations_feed.dart';
import '../../domain/entities/assistant_handoff_ticket.dart';
import '../../domain/entities/assistant_message_entity.dart';
import '../../domain/entities/assistant_rich_text.dart';
import '../../domain/entities/assistant_stream_event.dart';
import '../../domain/entities/assistant_thread.dart';
import '../models/assistant_conversation_model.dart';
import '../models/assistant_message_model.dart';
import '../models/assistant_reply_models.dart';
import '../models/assistant_stream_event_model.dart';
import 'assistant_block_mapper.dart';

extension AssistantMessageMapper on AssistantMessageModel {
  /// The rich text is parsed HERE, once — never in a widget's `build`.
  AssistantMessageEntity toEntity() {
    final entityBlocks = blocks.toEntities();
    final entityRole = roleOf(role);
    return AssistantMessageEntity(
      id: id,
      role: entityRole,
      conversationId: conversationId,
      content: content,
      richText: AssistantRichText.parse(_displayText(entityRole, entityBlocks)),
      blocks: entityBlocks,
      feedback: feedbackOf(feedback),
      createdAt: createdAt,
    );
  }

  /// [content] (== the `text` block — L6); an assistant reply with no
  /// content falls back to its `text` blocks. A user bubble renders its
  /// content only (its streamed copy has no blocks — L14).
  String _displayText(AssistantRole role, List<AssistantBlock> blocks) {
    if (content.trim().isNotEmpty || role != AssistantRole.assistant) {
      return content;
    }
    return blocks
        .whereType<AssistantTextBlock>()
        .map((block) => block.text)
        .where((text) => text.trim().isNotEmpty)
        .join('\n\n');
  }

  static AssistantRole roleOf(String wire) => switch (wire) {
    'user' => AssistantRole.user,
    'assistant' => AssistantRole.assistant,
    'system' => AssistantRole.system,
    _ => AssistantRole.other,
  };

  static AssistantFeedback feedbackOf(String? wire) => switch (wire) {
    'up' => AssistantFeedback.up,
    'down' => AssistantFeedback.down,
    _ => AssistantFeedback.none,
  };

  /// The body value of `POST …/messages/{id}/feedback` (`null` clears).
  static String? feedbackWire(AssistantFeedback feedback) => switch (feedback) {
    AssistantFeedback.up => 'up',
    AssistantFeedback.down => 'down',
    AssistantFeedback.none => null,
  };
}

extension AssistantConversationMapper on AssistantConversationModel {
  AssistantConversationEntity toEntity() => AssistantConversationEntity(
    id: id,
    title: title,
    language: language,
    status: statusOf(status),
    supportTicketId: supportTicketId,
    lastMessageAt: lastMessageAt,
    lastMessagePreview: lastMessagePreview,
    createdAt: createdAt,
  );

  static AssistantConversationStatus statusOf(String wire) => switch (wire) {
    'active' => AssistantConversationStatus.active,
    'handed_off' => AssistantConversationStatus.handedOff,
    'closed' => AssistantConversationStatus.closed,
    _ => AssistantConversationStatus.other,
  };
}

extension AssistantConversationsPageMapper on AssistantConversationsPageModel {
  AssistantConversationsFeed toEntity() => AssistantConversationsFeed(
    items: [for (final item in items) item.toEntity()],
    page: page,
    hasMore: hasMore,
    total: total,
  );
}

extension AssistantConversationDetailMapper
    on AssistantConversationDetailModel {
  AssistantThread toEntity() => AssistantThread.loaded(
    conversation: conversation.toEntity(),
    messages: [for (final message in messages) message.toEntity()],
  );
}

extension AssistantStreamEventMapper on AssistantStreamEventModel {
  AssistantStreamEvent toEntity() => switch (this) {
    AssistantStreamStartedModel(:final conversationId) =>
      AssistantStreamStarted(conversationId: conversationId),
    AssistantStreamUserMessageModel(:final conversationId, :final message) =>
      AssistantStreamUserMessage(
        conversationId: conversationId,
        message: message.toEntity(),
      ),
    AssistantStreamTextDeltaModel(:final delta) => AssistantStreamTextDelta(
      delta: delta,
    ),
    AssistantStreamToolStartedModel(:final name, :final callId) =>
      AssistantStreamToolStarted(name: name, callId: callId),
    AssistantStreamToolFinishedModel(:final name, :final callId, :final ok) =>
      AssistantStreamToolFinished(name: name, callId: callId, ok: ok),
    AssistantStreamBlockModel(:final block) => AssistantStreamBlock(
      block: block.toEntity(),
    ),
    AssistantStreamCompletedModel(:final conversationId, :final message) =>
      AssistantStreamCompleted(
        conversationId: conversationId,
        message: message.toEntity(),
      ),
    AssistantStreamFailedModel(:final code, :final message) =>
      AssistantStreamFailed(code: code, message: message),
  };
}

extension AssistantActionResultMapper on AssistantActionResultModel {
  AssistantActionResult toEntity() =>
      AssistantActionResult(message: message, blocks: blocks.toEntities());
}

extension AssistantHandoffTicketMapper on AssistantHandoffTicketModel {
  AssistantHandoffTicket toEntity() => AssistantHandoffTicket(
    ticketId: ticketId,
    ticketNumber: ticketNumber,
    message: message,
  );
}

extension AssistantAvailabilityMapper on AssistantAvailabilityModel {
  AssistantAvailability toEntity() => AssistantAvailability(
    enabled: enabled,
    allowGuests: allowGuests,
    featureFlag: featureFlag,
  );
}
