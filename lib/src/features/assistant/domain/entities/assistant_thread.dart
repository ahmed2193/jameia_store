import 'package:equatable/equatable.dart';

import 'assistant_block.dart';
import 'assistant_conversation_entity.dart';
import 'assistant_live_turn.dart';
import 'assistant_message_entity.dart';

/// One row of the chat list.
sealed class AssistantThreadEntry extends Equatable {
  const AssistantThreadEntry();

  /// Stable list identity (`ValueKey`, "animate once" bookkeeping).
  String get key;
}

final class AssistantMessageEntry extends AssistantThreadEntry {
  const AssistantMessageEntry(this.message);

  final AssistantMessageEntity message;

  @override
  String get key => message.key;

  @override
  List<Object?> get props => [message];
}

/// A reply that ended without a stored message — failed or stopped — kept on
/// screen with what streamed.
final class AssistantTurnEntry extends AssistantThreadEntry {
  const AssistantTurnEntry(this.turn);

  final AssistantLiveTurn turn;

  @override
  String get key => turn.key;

  @override
  List<Object?> get props => [turn];
}

/// "New chat started": the server closed the thread and the message went to
/// a new one.
final class AssistantDividerEntry extends AssistantThreadEntry {
  const AssistantDividerEntry(this.key);

  @override
  final String key;

  @override
  List<Object?> get props => [key];
}

/// The open conversation as the chat shows it: the server's messages plus
/// the local rows of this session (drafts, failed / stopped replies,
/// dividers), oldest first. The in-flight reply is NOT here — it lives next
/// to the thread (`AssistantChatState.liveTurn`) so a streamed word rebuilds
/// only its own bubble.
class AssistantThread extends Equatable {
  const AssistantThread({
    this.conversation,
    this.entries = const <AssistantThreadEntry>[],
    this.conversationLost = false,
  });

  static const AssistantThread empty = AssistantThread();

  factory AssistantThread.loaded({
    required AssistantConversationEntity conversation,
    required List<AssistantMessageEntity> messages,
  }) => AssistantThread(
    conversation: conversation,
    entries: [for (final message in messages) AssistantMessageEntry(message)],
  );

  static const String dividerKeyPrefix = 'divider:';
  static const String handoffKeyPrefix = 'handoff:';

  final AssistantConversationEntity? conversation;
  final List<AssistantThreadEntry> entries;

  /// The server no longer knows [conversation] (L9): nothing may be sent to
  /// it any more; the chat offers a new one.
  final bool conversationLost;

  /// The id to send with the next message; `null` starts a new conversation.
  String? get conversationId => conversationLost ? null : conversation?.id;

  bool get isEmpty => entries.isEmpty;

  /// No message can go to this thread: "This chat has ended".
  bool get hasEnded => conversationLost || (conversation?.isClosed ?? false);
  bool get isHandedOff => conversation?.isHandedOff ?? false;

  /// "Talk to a person" needs a live, still automated conversation.
  bool get canHandOff => !conversationLost && (conversation?.isActive ?? false);

  String? get lastKey => entries.isEmpty ? null : entries.last.key;

  /// The newest support ticket number shown in the thread.
  String? get ticketNumber {
    for (final entry in entries.reversed) {
      if (entry is! AssistantMessageEntry) continue;
      for (final block in entry.message.blocks.reversed) {
        if (block is AssistantHandoffBlock) return block.ticketNumber;
      }
    }
    return null;
  }

  /// The reply whose suggestion chips are live: only the LAST row, when it
  /// is a stored assistant reply with chips. Anything sent after it (even a
  /// draft) retires them.
  String? get suggestionsKey {
    if (entries.isEmpty) return null;
    final last = entries.last;
    if (last is! AssistantMessageEntry) return null;
    final message = last.message;
    return message.isAssistant && message.suggestions.isNotEmpty
        ? last.key
        : null;
  }

  AssistantMessageEntity? messageById(String id) {
    for (final entry in entries) {
      if (entry is AssistantMessageEntry && entry.message.id == id) {
        return entry.message;
      }
    }
    return null;
  }

  /// The proposal [actionId], wherever it sits (stored or failed reply).
  AssistantCartActionBlock? cartAction(String actionId) {
    for (final entry in entries) {
      for (final block in _blocksOf(entry)) {
        if (block is AssistantCartActionBlock && block.actionId == actionId) {
          return block;
        }
      }
    }
    return null;
  }

  AssistantThread append(AssistantThreadEntry entry) =>
      _copy(entries: [...entries, entry]);

  AssistantThread remove(String key) => _copy(
    entries: [
      for (final entry in entries)
        if (entry.key != key) entry,
    ],
  );

  /// Swaps the row [key] for [entry] in place.
  AssistantThread replace(String key, AssistantThreadEntry entry) => _copy(
    entries: [
      for (final current in entries)
        if (current.key == key) entry else current,
    ],
  );

  /// The draft [key] changed state (sending ⇄ failed).
  AssistantThread markDraft(String key, AssistantDelivery delivery) => _copy(
    entries: [
      for (final entry in entries)
        if (entry is AssistantMessageEntry && entry.key == key)
          AssistantMessageEntry(entry.message.copyWith(delivery: delivery))
        else
          entry,
    ],
  );

  /// `message_start`. The same id changes nothing. A new id for a thread
  /// that had one means the server closed it (message / token cap): the
  /// message went to a fresh conversation, marked by a divider right above
  /// the customer's bubble [draftKey].
  AssistantThread startConversation({
    required String conversationId,
    required String draftKey,
    String title = '',
  }) {
    final current = conversation;
    if (current != null && current.id == conversationId && !conversationLost) {
      return this;
    }
    final fresh = AssistantConversationEntity(id: conversationId, title: title);
    if (current == null) {
      return AssistantThread(conversation: fresh, entries: entries);
    }
    return AssistantThread(
      conversation: fresh,
      entries: [
        for (final entry in entries) ...[
          if (entry.key == draftKey)
            AssistantDividerEntry('$dividerKeyPrefix$conversationId'),
          entry,
        ],
      ],
    );
  }

  /// `user_message`: the server copy replaces the draft [draftKey] in place
  /// (same list key, so the row does not re-animate).
  AssistantThread confirmDraft(
    String draftKey,
    AssistantMessageEntity message,
  ) => replace(
    draftKey,
    AssistantMessageEntry(message.copyWith(clientKey: draftKey)),
  );

  /// `message_end`: the stored reply joins the thread under the live turn's
  /// key. A reply carrying a `handoff` card means the ASSISTANT handed the
  /// chat to a person (N6): the thread becomes handed off like after "Talk
  /// to a person".
  AssistantThread completeTurn(AssistantMessageEntity message) {
    final appended = append(AssistantMessageEntry(message));
    final handoff = message.blocks.whereType<AssistantHandoffBlock>();
    final current = conversation;
    if (handoff.isEmpty || current == null || !current.isActive) {
      return appended;
    }
    return appended._copy(
      conversation: current.copyWith(
        status: AssistantConversationStatus.handedOff,
        supportTicketId: handoff.last.ticketId,
      ),
    );
  }

  /// L9: the conversation is gone server-side.
  AssistantThread loseConversation() => _copy(conversationLost: true);

  /// "Talk to a person" succeeded.
  AssistantThread handOff({
    required String ticketId,
    required String ticketNumber,
  }) {
    final handedOff = _copy(
      conversation: conversation?.copyWith(
        status: AssistantConversationStatus.handedOff,
        supportTicketId: ticketId,
      ),
    );
    // The server's thread may already carry the ticket card.
    if (ticketNumber.isEmpty || ticketNumber == this.ticketNumber) {
      return handedOff;
    }
    return handedOff.append(
      AssistantMessageEntry(
        AssistantMessageEntity(
          id: '',
          role: AssistantRole.assistant,
          conversationId: conversation?.id ?? '',
          blocks: [
            AssistantHandoffBlock(
              ticketId: ticketId,
              ticketNumber: ticketNumber,
            ),
          ],
          clientKey: '$handoffKeyPrefix$ticketId',
        ),
      ),
    );
  }

  /// A confirm reply: the returned `cart_action` (same [actionId]) replaces
  /// the proposal where it is, and the other returned blocks (the
  /// `cart_summary`) go right after it in the same reply.
  AssistantThread replaceCartAction(
    String actionId,
    List<AssistantBlock> returned,
  ) {
    AssistantCartActionBlock? updated;
    final others = <AssistantBlock>[];
    for (final block in returned) {
      if (updated == null &&
          block is AssistantCartActionBlock &&
          block.actionId == actionId) {
        updated = block;
      } else if (AssistantCards.isCard(block)) {
        others.add(block);
      }
    }
    final current = cartAction(actionId);
    final replacement =
        updated ?? current?.withStatus(AssistantActionStatus.confirmed);
    if (replacement == null) return this;
    return _mapCartAction(actionId, (_) => [replacement, ...others]);
  }

  /// The proposal can no longer be confirmed (404 — L7).
  AssistantThread expireCartAction(String actionId) => _mapCartAction(
    actionId,
    (block) => [block.withStatus(AssistantActionStatus.expired)],
  );

  /// The thumbs of message [messageId].
  AssistantThread withFeedback(String messageId, AssistantFeedback feedback) =>
      _copy(
        entries: [
          for (final entry in entries)
            if (entry is AssistantMessageEntry && entry.message.id == messageId)
              AssistantMessageEntry(entry.message.copyWith(feedback: feedback))
            else
              entry,
        ],
      );

  AssistantThread _mapCartAction(
    String actionId,
    List<AssistantBlock> Function(AssistantCartActionBlock block) map,
  ) {
    List<AssistantBlock> mapBlocks(List<AssistantBlock> blocks) => [
      for (final block in blocks)
        if (block is AssistantCartActionBlock && block.actionId == actionId)
          ...map(block)
        else
          block,
    ];
    return _copy(
      entries: [
        for (final entry in entries)
          switch (entry) {
            AssistantMessageEntry(:final message) => AssistantMessageEntry(
              message.copyWith(blocks: mapBlocks(message.blocks)),
            ),
            AssistantTurnEntry(:final turn) => AssistantTurnEntry(
              turn.withCards(mapBlocks(turn.cards)),
            ),
            AssistantDividerEntry() => entry,
          },
      ],
    );
  }

  static List<AssistantBlock> _blocksOf(AssistantThreadEntry entry) =>
      switch (entry) {
        AssistantMessageEntry(:final message) => message.blocks,
        AssistantTurnEntry(:final turn) => turn.cards,
        AssistantDividerEntry() => const [],
      };

  AssistantThread _copy({
    AssistantConversationEntity? conversation,
    List<AssistantThreadEntry>? entries,
    bool? conversationLost,
  }) => AssistantThread(
    conversation: conversation ?? this.conversation,
    entries: entries ?? this.entries,
    conversationLost: conversationLost ?? this.conversationLost,
  );

  @override
  List<Object?> get props => [conversation, entries, conversationLost];
}
