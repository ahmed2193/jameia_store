import 'package:equatable/equatable.dart';

import 'rider_chat_message.dart';

/// The conversation with the rider of one order: the messages, oldest
/// first, whether the rider is typing right now, and how far the customer
/// has read it ([readUpTo], kept with the conversation across map opens).
class RiderChat extends Equatable {
  const RiderChat({
    this.messages = const <RiderChatMessage>[],
    this.riderTyping = false,
    this.readUpTo,
  });

  final List<RiderChatMessage> messages;
  final bool riderTyping;

  /// When the last message the customer has seen was sent (`null`: none).
  final DateTime? readUpTo;

  /// The rider's messages sent after [readUpTo] (every one when `null`).
  int unreadAfter(DateTime? readUpTo) => messages
      .where(
        (message) =>
            message.fromRider &&
            (readUpTo == null || message.sentAt.isAfter(readUpTo)),
      )
      .length;

  @override
  List<Object?> get props => [messages, riderTyping, readUpTo];
}
