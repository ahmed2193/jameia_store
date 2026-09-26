import 'package:equatable/equatable.dart';

import 'assistant_block.dart';
import 'assistant_rich_text.dart';

enum AssistantRole { user, assistant, system, other }

/// A thumbs rating on a message (`feedback`: `up` | `down` | `null`).
enum AssistantFeedback { up, down, none }

/// Where a message the customer typed stands. Server messages are [sent].
enum AssistantDelivery { sending, sent, failed }

/// One message of a conversation (`GET …/conversations/{id}` → `messages[]`,
/// `user_message` / `message_end` frames).
///
/// A user bubble renders [content] (its streamed copy has no blocks — L14);
/// an assistant reply renders [richText] (parsed once, from [content] or its
/// `text` blocks), then [cards], then [suggestions].
class AssistantMessageEntity extends Equatable {
  const AssistantMessageEntity({
    required this.id,
    required this.role,
    this.conversationId = '',
    this.content = '',
    this.richText = AssistantRichText.empty,
    this.blocks = const <AssistantBlock>[],
    this.feedback = AssistantFeedback.none,
    this.createdAt,
    this.clientKey,
    this.delivery = AssistantDelivery.sent,
  });

  /// A bubble the customer just typed, shown before the server knows it.
  factory AssistantMessageEntity.draft({
    required String clientKey,
    required String text,
    String conversationId = '',
  }) => AssistantMessageEntity(
    id: '',
    role: AssistantRole.user,
    conversationId: conversationId,
    content: text,
    clientKey: clientKey,
    delivery: AssistantDelivery.sending,
  );

  /// Server id; `''` until the server stored the message.
  final String id;
  final AssistantRole role;
  final String conversationId;
  final String content;
  final AssistantRichText richText;
  final List<AssistantBlock> blocks;
  final AssistantFeedback feedback;
  final DateTime? createdAt;

  /// The list key the message was born with in this session (a draft or a
  /// live reply), kept when the server copy replaces it so the row is not
  /// rebuilt nor re-animated. `null` for messages loaded from history.
  final String? clientKey;
  final AssistantDelivery delivery;

  /// Stable list identity.
  String get key => clientKey ?? id;

  bool get isUser => role == AssistantRole.user;
  bool get isAssistant => role == AssistantRole.assistant;
  bool get isPersisted => id.isNotEmpty;

  /// Thumbs are offered on stored assistant replies only (the server takes
  /// them on user messages too — L16 — but that makes no sense to show).
  bool get canRate => isAssistant && isPersisted;

  bool get hasText => !richText.isEmpty;

  /// What a screen reader announces when the reply lands: the start of the
  /// text, cut on a word, never the whole (up to 8000-char) reply.
  String get spokenPreview {
    final text = richText.plainText.replaceAll(_space, ' ').trim();
    if (text.length <= spokenPreviewLength) return text;
    final cut = text.lastIndexOf(' ', spokenPreviewLength);
    return '${text.substring(0, cut > 0 ? cut : spokenPreviewLength)}…';
  }

  static const int spokenPreviewLength = 140;
  static final RegExp _space = RegExp(r'\s+');

  /// The cards between the text and the chips, in server order (adjacent
  /// product rails merged, empty cards dropped — see `AssistantCards`).
  List<AssistantBlock> get cards => AssistantCards.of(blocks);

  bool get isSystem => role == AssistantRole.system;

  /// The chips of the LAST `actions` block.
  List<AssistantSuggestion> get suggestions {
    for (final block in blocks.reversed) {
      if (block is AssistantActionsBlock) return block.suggestions;
    }
    return const [];
  }

  AssistantMessageEntity copyWith({
    List<AssistantBlock>? blocks,
    AssistantFeedback? feedback,
    String? clientKey,
    AssistantDelivery? delivery,
  }) => AssistantMessageEntity(
    id: id,
    role: role,
    conversationId: conversationId,
    content: content,
    richText: richText,
    blocks: blocks ?? this.blocks,
    feedback: feedback ?? this.feedback,
    createdAt: createdAt,
    clientKey: clientKey ?? this.clientKey,
    delivery: delivery ?? this.delivery,
  );

  @override
  List<Object?> get props => [
    id,
    role,
    conversationId,
    content,
    richText,
    blocks,
    feedback,
    createdAt,
    clientKey,
    delivery,
  ];
}
