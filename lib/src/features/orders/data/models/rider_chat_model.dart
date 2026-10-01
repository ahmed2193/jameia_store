import '../../../../core/data/models/json_read.dart';
import 'rider_chat_message_model.dart';

/// The rider chat of an order: `{ messages: [message], riderTyping,
/// readUpTo }` — a malformed message is skipped; `readUpTo` (how far the
/// customer has read) is absent until they have read any of it.
class RiderChatModel {
  const RiderChatModel({
    this.messages = const <RiderChatMessageModel>[],
    this.riderTyping = false,
    this.readUpTo,
  });

  factory RiderChatModel.fromJson(Map<String, dynamic> json) => RiderChatModel(
    messages: JsonRead.rows(
      json[messagesKey],
      RiderChatMessageModel.fromJson,
      logName: _logName,
    ),
    riderTyping: JsonRead.flag(json[riderTypingKey]),
    readUpTo: JsonRead.dateTime(json[readUpToKey]),
  );

  static const String messagesKey = 'messages';
  static const String riderTypingKey = 'riderTyping';
  static const String readUpToKey = 'readUpTo';
  static const String _logName = 'RiderChatModel';

  final List<RiderChatMessageModel> messages;
  final bool riderTyping;
  final DateTime? readUpTo;

  Map<String, dynamic> toJson() => <String, dynamic>{
    messagesKey: [for (final message in messages) message.toJson()],
    riderTypingKey: riderTyping,
    readUpToKey: ?readUpTo?.toUtc().toIso8601String(),
  };
}
