import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/rider_chat.dart';

/// The chat with the rider on the live map: the conversation, whether the
/// chat sheet is open, what the customer has read ([readUpTo]), a message
/// on its way ([sending]), and a [failure] to tell — transient, cleared by
/// every [copyWith].
class RiderChatState extends Equatable {
  const RiderChatState({
    this.chat = const RiderChat(),
    this.open = false,
    this.readUpTo,
    this.sending = false,
    this.failure,
  });

  final RiderChat chat;
  final bool open;
  final DateTime? readUpTo;
  final bool sending;
  final Failure? failure;

  /// The rider's messages the customer has not seen (none while open).
  /// [readUpTo] is seeded from the conversation ([RiderChat.readUpTo]), so
  /// what was read on an earlier map open is not counted again.
  int get unread => open ? 0 : chat.unreadAfter(readUpTo);

  RiderChatState copyWith({
    RiderChat? chat,
    bool? open,
    DateTime? readUpTo,
    bool? sending,
    Failure? failure,
  }) => RiderChatState(
    chat: chat ?? this.chat,
    open: open ?? this.open,
    readUpTo: readUpTo ?? this.readUpTo,
    sending: sending ?? this.sending,
    failure: failure,
  );

  @override
  List<Object?> get props => [chat, open, readUpTo, sending, failure];
}
