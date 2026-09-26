import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';
import 'assistant_block_model.dart';

/// One message: `{ _id, conversationId, role, content, blocks[], feedback,
/// createdAt, updatedAt }` — the detail's `messages[]` and the
/// `user_message` / `message_end` frames.
class AssistantMessageModel {
  const AssistantMessageModel({
    required this.id,
    this.conversationId = '',
    this.role = '',
    this.content = '',
    this.blocks = const <AssistantBlockModel>[],
    this.feedback,
    this.createdAt,
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String conversationIdKey = 'conversationId';
  static const String roleKey = 'role';
  static const String contentKey = 'content';
  static const String blocksKey = 'blocks';
  static const String feedbackKey = 'feedback';
  static const String createdAtKey = 'createdAt';

  final String id;
  final String conversationId;

  /// `user` | `assistant` | `system`.
  final String role;
  final String content;
  final List<AssistantBlockModel> blocks;

  /// `up` | `down` | `null`.
  final String? feedback;

  /// Wrong on `message_end` (it repeats the user message's — L15): shown
  /// nowhere, never used for ordering.
  final DateTime? createdAt;

  /// Throws [ParsingException] without an id: thumbs and the list key need
  /// it.
  factory AssistantMessageModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('message: id missing');
    return AssistantMessageModel(
      id: id,
      conversationId: JsonRead.string(json[conversationIdKey]) ?? '',
      role: JsonRead.string(json[roleKey]) ?? '',
      content: json[contentKey] is String ? json[contentKey] as String : '',
      blocks: AssistantBlockModel.listFrom(json[blocksKey]),
      feedback: JsonRead.string(json[feedbackKey]),
      createdAt: JsonRead.dateTime(json[createdAtKey]),
    );
  }
}
