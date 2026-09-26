import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/assistant_conversation_entity.dart';
import '../../domain/entities/assistant_live_turn.dart';
import '../../domain/entities/assistant_thread.dart';

enum AssistantChatStatus {
  /// A new chat (welcome view) or a loaded thread.
  ready,

  /// A thread is being read (skeleton bubbles).
  loading,

  /// The thread could not be read (error view + retry).
  error,

  /// The assistant needs a signed-in customer (guests off, or the session is
  /// gone): the sign-in prompt.
  signedOut,
}

/// Which call produced [AssistantChatState.failure].
enum AssistantChatAction { load, send, confirm, rate, handOff }

/// One-shot things the page reacts to once (snack bar, haptic).
enum AssistantChatNotice {
  /// A reply ended in an error or a dropped connection.
  turnFailed,

  /// A message could not be sent: [AssistantChatState.noticeMessage] holds
  /// the server's in-band text, when there is one.
  sendFailed,

  /// A cart proposal can no longer be confirmed (404 — L7).
  actionExpired,

  /// A thumbs rating was saved.
  feedbackSent,

  /// A person will answer: [AssistantChatState.noticeMessage] is the
  /// server's confirmation, shown as sent.
  handedOff,

  /// The opened conversation no longer exists; a new chat is shown instead.
  conversationUnavailable,
}

/// The chat screen: the thread, the reply being streamed next to it (so a
/// streamed word rebuilds only its own bubble) and the request flags.
class AssistantChatState extends Equatable {
  const AssistantChatState({
    this.status = AssistantChatStatus.ready,
    this.thread = AssistantThread.empty,
    this.liveTurn,
    this.resumable,
    this.confirmingActionIds = const <String>{},
    this.actionMessages = const <String, String>{},
    this.isHandingOff = false,
    this.cartRevision = 0,
    this.failure,
    this.failedAction,
    this.notice,
    this.noticeMessage,
  });

  final AssistantChatStatus status;
  final AssistantThread thread;

  /// The reply being streamed; `null` between turns.
  final AssistantLiveTurn? liveTurn;

  /// The customer's last conversation, still open ("Continue your last
  /// chat" on the welcome view).
  final AssistantConversationEntity? resumable;

  /// Cart proposals whose confirm is in flight (one request per id).
  final Set<String> confirmingActionIds;

  /// The confirm reply's `message` per confirmed proposal, shown as sent.
  final Map<String, String> actionMessages;
  final bool isHandingOff;

  /// Bumped when a confirmed proposal changed the server cart: the page asks
  /// the cart to refetch.
  final int cartRevision;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  /// Transient, set together with [failure].
  final AssistantChatAction? failedAction;

  /// Transient one-shot.
  final AssistantChatNotice? notice;

  /// Transient server text for [notice], shown as sent.
  final String? noticeMessage;

  bool get isStreaming => liveTurn?.isActive ?? false;

  /// Nothing said yet: the welcome view.
  bool get isWelcome =>
      status == AssistantChatStatus.ready && thread.isEmpty && liveTurn == null;

  /// A message may go out now.
  bool get canSend =>
      status == AssistantChatStatus.ready && !isStreaming && !thread.hasEnded;

  /// "Talk to a person" is offered.
  bool get canHandOff => thread.canHandOff && !isStreaming && !isHandingOff;

  /// The reply whose suggestion chips are live: none while a turn streams
  /// or once the chat can take no message (a chip would do nothing).
  String? get suggestionsKey => canSend ? thread.suggestionsKey : null;

  AssistantChatState copyWith({
    AssistantChatStatus? status,
    AssistantThread? thread,
    AssistantLiveTurn? liveTurn,
    bool clearLiveTurn = false,
    AssistantConversationEntity? resumable,
    bool clearResumable = false,
    Set<String>? confirmingActionIds,
    Map<String, String>? actionMessages,
    bool? isHandingOff,
    int? cartRevision,
    Failure? failure,
    AssistantChatAction? failedAction,
    AssistantChatNotice? notice,
    String? noticeMessage,
  }) => AssistantChatState(
    status: status ?? this.status,
    thread: thread ?? this.thread,
    liveTurn: clearLiveTurn ? null : liveTurn ?? this.liveTurn,
    resumable: clearResumable ? null : resumable ?? this.resumable,
    confirmingActionIds: confirmingActionIds ?? this.confirmingActionIds,
    actionMessages: actionMessages ?? this.actionMessages,
    isHandingOff: isHandingOff ?? this.isHandingOff,
    cartRevision: cartRevision ?? this.cartRevision,
    failure: failure,
    failedAction: failedAction,
    notice: notice,
    noticeMessage: noticeMessage,
  );

  @override
  List<Object?> get props => [
    status,
    thread,
    liveTurn,
    resumable,
    confirmingActionIds,
    actionMessages,
    isHandingOff,
    cartRevision,
    failure,
    failedAction,
    notice,
    noticeMessage,
  ];
}
