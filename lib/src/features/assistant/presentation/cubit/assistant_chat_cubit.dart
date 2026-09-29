import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/assistant_block.dart';
import '../../domain/entities/assistant_live_turn.dart';
import '../../domain/entities/assistant_message_entity.dart';
import '../../domain/entities/assistant_prompt.dart';
import '../../domain/entities/assistant_stream_event.dart';
import '../../domain/entities/assistant_thread.dart';
import '../../domain/usecases/confirm_assistant_action_usecase.dart';
import '../../domain/usecases/get_assistant_conversation_usecase.dart';
import '../../domain/usecases/get_assistant_conversations_usecase.dart';
import '../../domain/usecases/rate_assistant_message_usecase.dart';
import '../../domain/usecases/request_assistant_handoff_usecase.dart';
import '../../domain/usecases/send_assistant_message_usecase.dart';
import 'assistant_chat_state.dart';

/// Page-scoped chat: one streamed turn at a time, cart proposals, thumbs and
/// handoff. The stream fold itself is `AssistantLiveTurn.apply` and the
/// thread edits are `AssistantThread`'s; this sequences calls, coalesces
/// streamed words and guards re-entry.
class AssistantChatCubit extends Cubit<AssistantChatState>
    with SafeCubitMixin<AssistantChatState> {
  AssistantChatCubit({
    required this._getConversations,
    required this._getConversation,
    required this._send,
    required this._confirm,
    required this._rate,
    required this._handOff,
  }) : super(const AssistantChatState());

  /// Streamed words are drawn at most once per interval (L3: deltas arrive
  /// 0–10 ms apart) — ≤ 20 emits a second whatever the server sends. Every
  /// other frame flushes at once.
  static const Duration streamFlushInterval = Duration(milliseconds: 50);

  static const String _draftPrefix = 'draft:';
  static const String _turnPrefix = 'turn:';
  static const int _resumableLimit = 1;

  final GetAssistantConversationsUseCase _getConversations;
  final GetAssistantConversationUseCase _getConversation;
  final SendAssistantMessageUseCase _send;
  final ConfirmAssistantActionUseCase _confirm;
  final RateAssistantMessageUseCase _rate;
  final RequestAssistantHandoffUseCase _handOff;

  StreamSubscription<AssistantStreamEvent>? _stream;
  Timer? _flushTimer;
  final StringBuffer _pendingText = StringBuffer();

  /// The server took the message (`message_start` / `user_message`): a
  /// failure from here on is a dropped reply, not an unsent message.
  bool _accepted = false;
  int _keySeq = 0;

  /// Bumped by every thread load and every send: a thread read that was in
  /// flight meanwhile is stale and dropped.
  int _threadGeneration = 0;
  String? _requestedThreadId;
  bool _reloadAfterTurn = false;

  /// Thumbs: the value the customer wants, the value the server has, and
  /// the messages with a request in flight (one each; the last tap wins).
  final Map<String, AssistantFeedback> _ratingWanted = {};
  final Map<String, AssistantFeedback> _ratingSaved = {};
  final Set<String> _ratingInFlight = {};

  // ---------------------------------------------------------------- opening

  /// A thread from history, a first question (e.g. from a product page) or
  /// the welcome view — which makes the only request on open: the latest
  /// conversation, for "Continue your last chat".
  Future<void> open({String? conversationId, String? initialPrompt}) async {
    if (conversationId != null) return loadThread(conversationId);
    if (initialPrompt != null && send(initialPrompt)) return;
    final result = await _getConversations(
      const GetAssistantConversationsParams(limit: _resumableLimit),
    );
    result.fold(
      (failure) {
        // Guests may be refused (`allowGuests: false`): the chat asks the
        // customer to sign in instead of letting them type into a 401.
        if (failure is UnauthorizedFailure && state.isWelcome) {
          safeEmit(state.copyWith(status: AssistantChatStatus.signedOut));
        }
      },
      (feed) {
        final resumable = feed.resumable;
        if (resumable != null && state.isWelcome) {
          safeEmit(state.copyWith(resumable: resumable));
        }
      },
    );
  }

  /// Opens [conversationId]. A [silent] reload (locale change) keeps the
  /// thread on screen and ignores failures.
  Future<void> loadThread(String conversationId, {bool silent = false}) async {
    _cancelStream();
    _requestedThreadId = conversationId;
    final generation = ++_threadGeneration;
    if (!silent) {
      safeEmit(
        state.copyWith(
          status: AssistantChatStatus.loading,
          clearLiveTurn: true,
          clearResumable: true,
        ),
      );
    }
    final result = await _getConversation(
      GetAssistantConversationParams(conversationId),
    );
    if (generation != _threadGeneration) return;
    result.fold(
      (failure) {
        if (silent) return;
        safeEmit(switch (failure) {
          UnauthorizedFailure() => state.copyWith(
            status: AssistantChatStatus.signedOut,
            failure: failure,
            failedAction: AssistantChatAction.load,
          ),
          NotFoundFailure() => state.copyWith(
            status: AssistantChatStatus.ready,
            thread: AssistantThread.empty,
            notice: AssistantChatNotice.conversationUnavailable,
          ),
          _ => state.copyWith(
            status: AssistantChatStatus.error,
            failure: failure,
            failedAction: AssistantChatAction.load,
          ),
        });
      },
      (thread) => safeEmit(
        state.copyWith(status: AssistantChatStatus.ready, thread: thread),
      ),
    );
  }

  /// Retry after the thread failed to load.
  Future<void> retryLoad() async {
    final id = _requestedThreadId;
    if (id != null) await loadThread(id);
  }

  /// The connection came back: a thread whose load failed loads again.
  Future<void> onReconnected() async {
    if (state.status == AssistantChatStatus.error) await retryLoad();
  }

  /// "Continue your last chat".
  Future<void> resume() async {
    final resumable = state.resumable;
    if (resumable != null) await loadThread(resumable.id);
  }

  /// Leaves the current thread for an empty one. The thread just left stays
  /// offered as "Continue your last chat" while it still takes messages.
  void startNewChat() {
    _cancelStream();
    ++_threadGeneration;
    _requestedThreadId = null;
    final thread = state.thread;
    final current = thread.conversation;
    safeEmit(
      AssistantChatState(
        resumable: current != null && current.isActive && !thread.hasEnded
            ? current
            : null,
        cartRevision: state.cartRevision,
        // A confirm still on its way stays guarded (and its reply is still
        // applied) if the customer comes back to that chat.
        confirmingActionIds: state.confirmingActionIds,
        actionMessages: state.actionMessages,
      ),
    );
  }

  // --------------------------------------------------------------- sending

  /// Sends [text] (typed, a chip's prompt, a starter). `false` when it cannot
  /// go: empty or over the limit, a reply still streaming, or the chat ended.
  bool send(String text) {
    final prompt = AssistantPrompt.validate(text);
    if (prompt == null || !state.canSend) return false;
    final draftKey = _nextKey(_draftPrefix);
    final thread = state.thread.append(
      AssistantMessageEntry(
        AssistantMessageEntity.draft(
          clientKey: draftKey,
          text: prompt.text,
          conversationId: state.thread.conversationId ?? '',
        ),
      ),
    );
    _startTurn(prompt, draftKey, thread);
    return true;
  }

  /// Answers the same question again after a failed or stopped reply: the
  /// kept reply goes and a new one answers the SAME bubble, under the same
  /// row key (the row turns back into the thinking bubble in place). Only
  /// the last row can be retried.
  void retryTurn(String turnKey) {
    final thread = state.thread;
    final last = thread.entries.isEmpty ? null : thread.entries.last;
    if (last is! AssistantTurnEntry || last.key != turnKey) return;
    final prompt = AssistantPrompt.validate(last.turn.prompt);
    if (prompt == null || !state.canSend) return;
    _startTurn(
      prompt,
      last.turn.userMessageKey,
      thread.remove(turnKey),
      turnKey: turnKey,
    );
  }

  /// Sends an unsent bubble (the last row) again.
  void retryDraft(String draftKey) {
    final thread = state.thread;
    final last = thread.entries.isEmpty ? null : thread.entries.last;
    if (last is! AssistantMessageEntry ||
        last.key != draftKey ||
        last.message.delivery != AssistantDelivery.failed) {
      return;
    }
    final prompt = AssistantPrompt.validate(last.message.content);
    if (prompt == null || !state.canSend) return;
    _startTurn(
      prompt,
      draftKey,
      thread.markDraft(draftKey, AssistantDelivery.sending),
    );
  }

  /// Stops the reply: the request is cancelled and what streamed stays. The
  /// server may still finish and save it; the next open of the thread shows
  /// it.
  void stop() {
    final turn = state.liveTurn;
    if (turn == null || !turn.isActive) return;
    final stopped = _withPending(turn).stop();
    _cancelStream();
    _endTurn(
      state.thread
          .markDraft(turn.userMessageKey, AssistantDelivery.sent)
          .append(AssistantTurnEntry(stopped)),
    );
  }

  void _startTurn(
    AssistantPrompt prompt,
    String userMessageKey,
    AssistantThread thread, {
    String? turnKey,
  }) {
    ++_threadGeneration; // a thread read in flight must not replace this turn
    _accepted = false;
    _pendingText.clear();
    final turn = AssistantLiveTurn(
      key: turnKey ?? _nextKey(_turnPrefix),
      prompt: prompt.text,
      userMessageKey: userMessageKey,
    );
    safeEmit(
      state.copyWith(thread: thread, liveTurn: turn, clearResumable: true),
    );
    _stream = _send(
      SendAssistantMessageParams(
        prompt: prompt,
        conversationId: thread.conversationId,
      ),
    ).listen(_onEvent, onError: _onError, onDone: _onDone);
  }

  void _onEvent(AssistantStreamEvent event) {
    final turn = state.liveTurn;
    if (turn == null || !turn.isActive) return;
    switch (event) {
      case AssistantStreamTextDelta(:final delta):
        _onDelta(delta);
      case AssistantStreamStarted(:final conversationId):
        _accepted = true;
        safeEmit(
          state.copyWith(
            thread: state.thread.startConversation(
              conversationId: conversationId,
              draftKey: turn.userMessageKey,
              title: turn.prompt,
            ),
          ),
        );
      case AssistantStreamUserMessage(:final conversationId, :final message):
        _accepted = true;
        safeEmit(
          state.copyWith(
            thread: state.thread
                .startConversation(
                  conversationId: conversationId,
                  draftKey: turn.userMessageKey,
                  title: turn.prompt,
                )
                .confirmDraft(turn.userMessageKey, message),
          ),
        );
      case AssistantStreamCompleted():
        final done = _withPending(turn).apply(event);
        _cancelStream();
        _endTurn(
          state.thread
              .markDraft(turn.userMessageKey, AssistantDelivery.sent)
              .completeTurn(done.message!),
        );
      case AssistantStreamFailed():
        final failed = _withPending(turn).apply(event);
        _cancelStream();
        var thread = state.thread;
        if (failed.lostConversation) thread = thread.loseConversation();
        if (_accepted) {
          _endTurn(
            thread.append(AssistantTurnEntry(failed)),
            notice: AssistantChatNotice.turnFailed,
          );
        } else {
          // Refused before the message was stored: the bubble is unsent. A
          // lost conversation (L9) is explained by the "chat ended" bar.
          final lost = failed.lostConversation;
          _endTurn(
            thread.markDraft(turn.userMessageKey, AssistantDelivery.failed),
            notice: lost
                ? AssistantChatNotice.conversationUnavailable
                : AssistantChatNotice.sendFailed,
            noticeMessage: lost ? null : failed.displayErrorMessage,
          );
        }
      case AssistantStreamToolStarted() ||
          AssistantStreamToolFinished() ||
          AssistantStreamBlock():
        safeEmit(state.copyWith(liveTurn: _withPending(turn).apply(event)));
    }
  }

  void _onError(Object error) {
    final failure = error is Failure ? error : const UnexpectedFailure();
    final turn = state.liveTurn;
    if (turn == null || !turn.isActive) return;
    _cancelStream();
    if (_accepted) {
      // The reply was cut: keep what streamed. Never re-sent automatically.
      _endTurn(
        state.thread.append(
          AssistantTurnEntry(_withPending(turn).drop(failure)),
        ),
        notice: AssistantChatNotice.turnFailed,
      );
      return;
    }
    // Never reached the server (400, 401, 429 after retries, offline).
    _endTurn(
      state.thread.markDraft(turn.userMessageKey, AssistantDelivery.failed),
      status: failure is UnauthorizedFailure
          ? AssistantChatStatus.signedOut
          : null,
      failure: failure,
      failedAction: AssistantChatAction.send,
    );
  }

  /// The stream closed without `message_end` / `error`.
  void _onDone() {
    final turn = state.liveTurn;
    if (turn == null || !turn.isActive) return;
    _onError(const NetworkFailure());
  }

  void _endTurn(
    AssistantThread thread, {
    AssistantChatStatus? status,
    Failure? failure,
    AssistantChatAction? failedAction,
    AssistantChatNotice? notice,
    String? noticeMessage,
  }) {
    safeEmit(
      state.copyWith(
        status: status,
        thread: thread,
        clearLiveTurn: true,
        failure: failure,
        failedAction: failedAction,
        notice: notice,
        noticeMessage: noticeMessage,
      ),
    );
    if (_reloadAfterTurn) {
      _reloadAfterTurn = false;
      unawaited(reloadForLocale());
    }
  }

  // ------------------------------------------------------ streamed words

  void _onDelta(String delta) {
    _pendingText.write(delta);
    if (_flushTimer != null) return; // the scheduled flush picks it up
    _flushText(); // leading edge: the first words show at once
    _flushTimer = Timer(streamFlushInterval, _onFlushTimer);
  }

  void _onFlushTimer() {
    _flushTimer = null;
    if (_pendingText.isEmpty) return;
    _flushText();
    _flushTimer = Timer(streamFlushInterval, _onFlushTimer);
  }

  void _flushText() {
    final turn = state.liveTurn;
    if (turn == null || _pendingText.isEmpty) return;
    final text = _pendingText.toString();
    _pendingText.clear();
    safeEmit(state.copyWith(liveTurn: turn.appendText(text)));
  }

  /// [turn] with the words not drawn yet — applied before any other frame so
  /// frames keep their order.
  AssistantLiveTurn _withPending(AssistantLiveTurn turn) {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_pendingText.isEmpty) return turn;
    final text = _pendingText.toString();
    _pendingText.clear();
    return turn.appendText(text);
  }

  void _cancelStream() {
    unawaited(_stream?.cancel());
    _stream = null;
    _flushTimer?.cancel();
    _flushTimer = null;
    _pendingText.clear();
  }

  // --------------------------------------------------------- cart proposals

  /// Confirms proposal [actionId]; one request per id however often it is
  /// tapped. On success the proposal and the returned cart snapshot replace
  /// it in place and the page refetches the cart.
  Future<void> confirmAction(String actionId) async {
    if (state.confirmingActionIds.contains(actionId)) return;
    final proposal = state.thread.cartAction(actionId);
    if (proposal == null || !proposal.isPending) return;
    safeEmit(
      state.copyWith(
        confirmingActionIds: {...state.confirmingActionIds, actionId},
        actionFailures: _withoutFailure(actionId),
      ),
    );
    final result = await _confirm(ConfirmAssistantActionParams(actionId));
    final confirming = {...state.confirmingActionIds}..remove(actionId);
    result.fold(
      (failure) => safeEmit(switch (failure) {
        // A late 404 never undoes a proposal already shown as confirmed.
        NotFoundFailure()
            when state.thread.cartAction(actionId)?.status ==
                AssistantActionStatus.confirmed =>
          state.copyWith(confirmingActionIds: confirming),
        NotFoundFailure() => state.copyWith(
          thread: state.thread.expireCartAction(actionId),
          confirmingActionIds: confirming,
          notice: AssistantChatNotice.actionExpired,
        ),
        UnauthorizedFailure() => state.copyWith(
          status: AssistantChatStatus.signedOut,
          confirmingActionIds: confirming,
          failure: failure,
          failedAction: AssistantChatAction.confirm,
        ),
        _ => state.copyWith(
          confirmingActionIds: confirming,
          actionFailures: {...state.actionFailures, actionId: failure},
          failure: failure,
          failedAction: AssistantChatAction.confirm,
        ),
      }),
      (reply) => safeEmit(
        state.copyWith(
          thread: state.thread.replaceCartAction(actionId, reply.blocks),
          confirmingActionIds: confirming,
          actionMessages: {...state.actionMessages, actionId: reply.message},
          cartRevision: state.cartRevision + 1,
        ),
      ),
    );
  }

  Map<String, Failure> _withoutFailure(String actionId) =>
      state.actionFailures.containsKey(actionId)
      ? ({...state.actionFailures}..remove(actionId))
      : state.actionFailures;

  // ------------------------------------------------------------------ thumbs

  /// Thumbs [tapped] on [messageId]; tapping the active one clears it. The
  /// change shows at once; one request per message is in flight and the
  /// last tap wins. A refusal rolls back to what the server has.
  Future<void> rate(String messageId, AssistantFeedback tapped) async {
    final message = state.thread.messageById(messageId);
    if (message == null || !message.canRate) return;
    final next = message.feedback == tapped ? AssistantFeedback.none : tapped;
    _ratingSaved.putIfAbsent(messageId, () => message.feedback);
    _ratingWanted[messageId] = next;
    safeEmit(
      state.copyWith(thread: state.thread.withFeedback(messageId, next)),
    );
    if (_ratingInFlight.add(messageId)) await _saveRating(messageId);
  }

  Future<void> _saveRating(String messageId) async {
    while (true) {
      final wanted = _ratingWanted[messageId];
      final saved = _ratingSaved[messageId];
      if (wanted == null || wanted == saved) break;
      final result = await _rate(
        RateAssistantMessageParams(messageId: messageId, feedback: wanted),
      );
      final failure = result.fold<Failure?>((failure) => failure, (_) => null);
      if (failure != null) {
        final rollback = saved ?? AssistantFeedback.none;
        _ratingWanted[messageId] = rollback;
        safeEmit(
          state.copyWith(
            thread: state.thread.withFeedback(messageId, rollback),
            failure: failure,
            failedAction: AssistantChatAction.rate,
          ),
        );
        break;
      }
      _ratingSaved[messageId] = wanted;
      if (_ratingWanted[messageId] == wanted &&
          wanted != AssistantFeedback.none) {
        safeEmit(state.copyWith(notice: AssistantChatNotice.feedbackSent));
      }
    }
    _ratingInFlight.remove(messageId);
  }

  // ----------------------------------------------------------------- handoff

  /// "Talk to a person" (one request; the body stays empty — never guessed).
  Future<void> handOff() async {
    final conversationId = state.thread.conversationId;
    if (conversationId == null || !state.canHandOff) return;
    safeEmit(state.copyWith(isHandingOff: true));
    final result = await _handOff(
      RequestAssistantHandoffParams(conversationId),
    );
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: failure is UnauthorizedFailure
              ? AssistantChatStatus.signedOut
              : null,
          isHandingOff: false,
          failure: failure,
          failedAction: AssistantChatAction.handOff,
        ),
      ),
      (ticket) => safeEmit(
        state.copyWith(
          thread: state.thread.conversationId == conversationId
              ? state.thread.handOff(
                  ticketId: ticket.ticketId,
                  ticketNumber: ticket.ticketNumber,
                )
              : null,
          isHandingOff: false,
          notice: AssistantChatNotice.handedOff,
          noticeMessage: ticket.message,
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ locale

  /// The app language changed: product names are resolved server-side, so
  /// the open thread is read again — after the reply streaming now.
  Future<void> reloadForLocale() async {
    if (state.isStreaming) {
      _reloadAfterTurn = true;
      return;
    }
    final id = state.thread.conversationId;
    if (id == null || state.status != AssistantChatStatus.ready) return;
    await loadThread(id, silent: true);
  }

  String _nextKey(String prefix) => '$prefix${++_keySeq}';

  @override
  Future<void> close() {
    _cancelStream();
    return super.close();
  }
}
