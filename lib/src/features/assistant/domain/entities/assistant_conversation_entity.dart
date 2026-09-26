import 'package:equatable/equatable.dart';

import 'assistant_rich_text.dart';

enum AssistantConversationStatus { active, handedOff, closed, other }

/// One assistant conversation (`GET /v1/assistant/conversations` rows, the
/// detail's `conversation`).
///
/// `messageCount` and token `usage` are deliberately not modelled: the count
/// is stale on the live host (L12) and usage is not the customer's business.
class AssistantConversationEntity extends Equatable {
  const AssistantConversationEntity({
    required this.id,
    this.title = '',
    this.language = '',
    this.status = AssistantConversationStatus.active,
    this.supportTicketId,
    this.lastMessageAt,
    this.lastMessagePreview = '',
    this.createdAt,
  });

  final String id;

  /// The first thing the customer asked.
  final String title;

  /// `en` | `ar`: the language the thread was started in.
  final String language;
  final AssistantConversationStatus status;
  final String? supportTicketId;
  final DateTime? lastMessageAt;

  /// The last message as the server stores it — markdown included.
  final String lastMessagePreview;
  final DateTime? createdAt;

  /// [lastMessagePreview] as one line of plain text, without the reply's
  /// markdown (`**Add to cart**` reads "Add to cart").
  String get previewText =>
      AssistantRichText.parse(lastMessagePreview).plainText
          .replaceAll(_space, ' ')
          .trim();

  static final RegExp _space = RegExp(r'\s+');

  bool get isActive => status == AssistantConversationStatus.active;
  bool get isHandedOff => status == AssistantConversationStatus.handedOff;

  /// A closed thread takes no message: the next send starts a new one.
  bool get isClosed => status == AssistantConversationStatus.closed;

  AssistantConversationEntity copyWith({
    AssistantConversationStatus? status,
    String? supportTicketId,
  }) => AssistantConversationEntity(
    id: id,
    title: title,
    language: language,
    status: status ?? this.status,
    supportTicketId: supportTicketId ?? this.supportTicketId,
    lastMessageAt: lastMessageAt,
    lastMessagePreview: lastMessagePreview,
    createdAt: createdAt,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    language,
    status,
    supportTicketId,
    lastMessageAt,
    lastMessagePreview,
    createdAt,
  ];
}
