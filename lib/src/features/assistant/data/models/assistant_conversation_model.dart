import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';
import 'assistant_message_model.dart';

/// One conversation (list row, the detail's `conversation`). `messageCount`
/// (stale — L12) and token `usage` are not read.
class AssistantConversationModel {
  const AssistantConversationModel({
    required this.id,
    this.title = '',
    this.language = '',
    this.status = '',
    this.supportTicketId,
    this.lastMessageAt,
    this.lastMessagePreview = '',
    this.createdAt,
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String titleKey = 'title';
  static const String languageKey = 'language';
  static const String statusKey = 'status';
  static const String supportTicketIdKey = 'supportTicketId';
  static const String lastMessageAtKey = 'lastMessageAt';
  static const String lastMessagePreviewKey = 'lastMessagePreview';
  static const String createdAtKey = 'createdAt';

  final String id;
  final String title;
  final String language;

  /// `active` | `handed_off` | `closed`.
  final String status;
  final String? supportTicketId;
  final DateTime? lastMessageAt;
  final String lastMessagePreview;
  final DateTime? createdAt;

  factory AssistantConversationModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('conversation: id missing');
    return AssistantConversationModel(
      id: id,
      title: JsonRead.string(json[titleKey]) ?? '',
      language: JsonRead.string(json[languageKey]) ?? '',
      status: JsonRead.string(json[statusKey]) ?? '',
      supportTicketId: JsonRead.string(json[supportTicketIdKey]),
      lastMessageAt: JsonRead.dateTime(json[lastMessageAtKey]),
      lastMessagePreview: JsonRead.string(json[lastMessagePreviewKey]) ?? '',
      createdAt: JsonRead.dateTime(json[createdAtKey]),
    );
  }
}

/// `GET /v1/assistant/conversations` → `{ data[], pagination }`.
class AssistantConversationsPageModel {
  const AssistantConversationsPageModel({
    this.items = const <AssistantConversationModel>[],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
  });

  static const String dataKey = 'data';
  static const String paginationKey = 'pagination';
  static const String totalKey = 'total';
  static const String pageKey = 'page';
  static const String hasMoreKey = 'hasMore';
  static const String _logName = 'AssistantConversationsPageModel';

  final List<AssistantConversationModel> items;
  final int total;
  final int page;
  final bool hasMore;

  factory AssistantConversationsPageModel.fromJson(
    Map<String, dynamic> json, {
    int requestedPage = 1,
  }) {
    if (json[dataKey] is! List) {
      throw const ParsingException('conversations: data is not a list');
    }
    final items = JsonRead.rows(
      json[dataKey],
      AssistantConversationModel.fromJson,
      logName: _logName,
    );
    final pagination = JsonRead.object(json[paginationKey]) ?? const {};
    return AssistantConversationsPageModel(
      items: items,
      total: JsonRead.integer(pagination[totalKey]) ?? items.length,
      page: JsonRead.integer(pagination[pageKey]) ?? requestedPage,
      hasMore: JsonRead.flag(pagination[hasMoreKey]),
    );
  }
}

/// `GET /v1/assistant/conversations/{id}` → `{ conversation, messages[] }`
/// (messages oldest first).
class AssistantConversationDetailModel {
  const AssistantConversationDetailModel({
    required this.conversation,
    this.messages = const <AssistantMessageModel>[],
  });

  static const String conversationKey = 'conversation';
  static const String messagesKey = 'messages';
  static const String _logName = 'AssistantConversationDetailModel';

  final AssistantConversationModel conversation;
  final List<AssistantMessageModel> messages;

  factory AssistantConversationDetailModel.fromJson(Map<String, dynamic> json) {
    final conversation = JsonRead.object(json[conversationKey]);
    if (conversation == null) {
      throw const ParsingException('conversation detail: conversation missing');
    }
    return AssistantConversationDetailModel(
      conversation: AssistantConversationModel.fromJson(conversation),
      messages: JsonRead.rows(
        json[messagesKey],
        AssistantMessageModel.fromJson,
        logName: _logName,
      ),
    );
  }
}
