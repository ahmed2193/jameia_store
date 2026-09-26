import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import 'assistant_block.dart';
import 'assistant_error_code.dart';
import 'assistant_message_entity.dart';
import 'assistant_rich_text.dart';
import 'assistant_stream_event.dart';

enum AssistantTurnPhase {
  /// Sent; nothing but the connection so far (1–4 s: tools run first — L2).
  thinking,

  /// Text is arriving.
  streaming,

  /// `message_end` landed: [AssistantLiveTurn.message] is the stored reply.
  completed,

  /// A terminal `error` frame, a dropped connection or a pre-stream failure.
  failed,

  /// The customer pressed Stop.
  stopped,
}

/// A running tool call (`tool_start` … `tool_end`).
class AssistantToolCall extends Equatable {
  const AssistantToolCall({required this.name, required this.callId});

  final String name;
  final String callId;

  @override
  List<Object?> get props => [name, callId];
}

/// The assistant reply being streamed — the business logic of the stream as
/// a pure fold: `turn = turn.apply(event)` for every frame.
///
/// Rendering order is canonical from the first frame: text on top, cards
/// under it in arrival order, chips last — the order `message_end` hydrates
/// (L4) — so swapping in the stored message moves nothing on screen. Chips
/// only exist on the stored message (L5).
class AssistantLiveTurn extends Equatable {
  const AssistantLiveTurn({
    required this.key,
    required this.prompt,
    required this.userMessageKey,
    this.phase = AssistantTurnPhase.thinking,
    this.text = '',
    this.richText = AssistantRichText.empty,
    this.cards = const <AssistantBlock>[],
    this.tools = const <AssistantToolCall>[],
    this.lastToolName,
    this.errorCode,
    this.errorMessage = '',
    this.failure,
    this.message,
  });

  /// List key; the stored reply inherits it so its row is not rebuilt.
  final String key;

  /// What the customer asked — Retry sends it again.
  final String prompt;

  /// The user bubble this turn answers.
  final String userMessageKey;
  final AssistantTurnPhase phase;

  /// Everything streamed so far, and its parse (redone per flush, not per
  /// frame: the cubit coalesces deltas).
  final String text;
  final AssistantRichText richText;

  /// Visible cards in arrival order.
  final List<AssistantBlock> cards;

  /// Running tool calls, oldest first.
  final List<AssistantToolCall> tools;

  /// The last tool that started. Live tools run for 0–23 ms (N1) — far too
  /// short to read — so the status line keeps naming it until the next tool
  /// or the first word.
  final String? lastToolName;

  /// In-band `error` frame (see `AssistantErrorCode`); shown as sent.
  final String? errorCode;
  final String errorMessage;

  /// A transport failure: the connection dropped or never opened.
  final Failure? failure;

  /// The stored reply, once [phase] is [AssistantTurnPhase.completed].
  final AssistantMessageEntity? message;

  bool get isActive =>
      phase == AssistantTurnPhase.thinking ||
      phase == AssistantTurnPhase.streaming;
  bool get isFailed => phase == AssistantTurnPhase.failed;
  bool get isStopped => phase == AssistantTurnPhase.stopped;

  /// Three dots until the first word arrives (tools and cards may come
  /// first).
  bool get showsTypingIndicator => isActive && richText.isEmpty;

  /// The status line under the dots: the latest running tool, else the last
  /// one that ran; `null` once text streams or the turn ended.
  String? get activeToolName {
    if (!showsTypingIndicator) return null;
    return tools.isEmpty ? lastToolName : tools.last.name;
  }

  /// The in-band error text to show, or `null` for the generic one: an
  /// `INTERNAL_ERROR` text is raw English even in Arabic (N4) and says
  /// nothing a customer can act on.
  String? get displayErrorMessage {
    if (errorMessage.isEmpty) return null;
    if (errorCode == AssistantErrorCode.internalError) return null;
    return errorMessage;
  }

  /// L7: the reply failed after proposing a cart change. The proposal was
  /// never stored, so confirming it would 404 — the customer is told to add
  /// the items from the product cards instead.
  bool get hasOrphanProposal =>
      isFailed &&
      cards.any((card) => card is AssistantCartActionBlock && card.isPending);

  /// The server does not know the conversation (L9): the thread id must be
  /// dropped and a new chat offered instead of Retry.
  bool get lostConversation =>
      isFailed && errorCode == AssistantErrorCode.resourceNotFound;

  AssistantLiveTurn apply(AssistantStreamEvent event) {
    if (!isActive) return this;
    return switch (event) {
      AssistantStreamStarted() || AssistantStreamUserMessage() => this,
      AssistantStreamTextDelta(:final delta) => appendText(delta),
      AssistantStreamToolStarted(:final name, :final callId) =>
        tools.any((tool) => tool.callId == callId)
            ? this
            : _copy(
                tools: [
                  ...tools,
                  AssistantToolCall(name: name, callId: callId),
                ],
                lastToolName: name,
              ),
      AssistantStreamToolFinished(:final callId) => _copy(
        tools: [
          for (final tool in tools)
            if (tool.callId != callId) tool,
        ],
      ),
      AssistantStreamBlock(:final block) => _withBlock(block),
      AssistantStreamCompleted(:final message) => _copy(
        phase: AssistantTurnPhase.completed,
        tools: const [],
        richText: AssistantRichText.parse(text),
        message: message.copyWith(clientKey: key),
      ),
      AssistantStreamFailed(:final code, :final message) => _copy(
        phase: AssistantTurnPhase.failed,
        tools: const [],
        richText: AssistantRichText.parse(text),
        errorCode: code,
        errorMessage: message,
      ),
    };
  }

  /// Appends coalesced deltas and re-parses the text once.
  ///
  /// While streaming, only COMPLETE words are drawn: the text is cut after
  /// its last whitespace. Deltas split words (`"اقت"` + `"راح"` live), and an
  /// Arabic word re-shapes its letters when the rest arrives — holding the
  /// partial word avoids that flicker. The whole text shows once the turn
  /// ends.
  AssistantLiveTurn appendText(String delta) {
    if (!isActive || delta.isEmpty) return this;
    final next = text + delta;
    return _copy(
      phase: AssistantTurnPhase.streaming,
      text: next,
      richText: AssistantRichText.parse(completeWordsOf(next)),
    );
  }

  /// [text] up to and including its last whitespace.
  static String completeWordsOf(String text) {
    final end = text.lastIndexOf(_whitespace);
    return end < 0 ? '' : text.substring(0, end + 1);
  }

  static final RegExp _whitespace = RegExp(r'\s');

  /// The customer stopped it: what streamed stays, marked stopped.
  AssistantLiveTurn stop() => isActive
      ? _copy(
          phase: AssistantTurnPhase.stopped,
          tools: const [],
          richText: AssistantRichText.parse(text),
        )
      : this;

  /// The connection broke or never opened (no terminal frame).
  AssistantLiveTurn drop(Failure failure) => isActive
      ? _copy(
          phase: AssistantTurnPhase.failed,
          tools: const [],
          failure: failure,
          richText: AssistantRichText.parse(text),
        )
      : this;

  /// The same turn with [cards] swapped (a confirmed / expired proposal).
  AssistantLiveTurn withCards(List<AssistantBlock> cards) =>
      _copy(cards: cards);

  /// A card for the reply, merged exactly as the stored message merges its
  /// blocks (`AssistantCards`): `text` blocks are not drawn from the stream
  /// (the deltas carry the text — L6), `actions` chips wait for the stored
  /// message (L5), an empty card is never shown.
  AssistantLiveTurn _withBlock(AssistantBlock block) {
    final next = AssistantCards.append(cards, block);
    return identical(next, cards) ? this : _copy(cards: next);
  }

  AssistantLiveTurn _copy({
    AssistantTurnPhase? phase,
    String? text,
    AssistantRichText? richText,
    List<AssistantBlock>? cards,
    List<AssistantToolCall>? tools,
    String? lastToolName,
    String? errorCode,
    String? errorMessage,
    Failure? failure,
    AssistantMessageEntity? message,
  }) => AssistantLiveTurn(
    key: key,
    prompt: prompt,
    userMessageKey: userMessageKey,
    phase: phase ?? this.phase,
    text: text ?? this.text,
    richText: richText ?? this.richText,
    cards: cards ?? this.cards,
    tools: tools ?? this.tools,
    lastToolName: lastToolName ?? this.lastToolName,
    errorCode: errorCode ?? this.errorCode,
    errorMessage: errorMessage ?? this.errorMessage,
    failure: failure ?? this.failure,
    message: message ?? this.message,
  );

  @override
  List<Object?> get props => [
    key,
    prompt,
    userMessageKey,
    phase,
    text,
    cards,
    tools,
    lastToolName,
    errorCode,
    errorMessage,
    failure,
    message,
  ];
}
