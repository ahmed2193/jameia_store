import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_block.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_cart_snapshot.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_conversation_entity.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_live_turn.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_message_entity.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_thread.dart';

void main() {
  const conversation = AssistantConversationEntity(id: 'c1', title: 'milk');
  const pending = AssistantCartActionBlock(
    actionId: 'act-1',
    items: [AssistantCartActionItem(productId: 'p1', quantity: 1)],
  );
  const chips = AssistantActionsBlock(
    suggestions: [AssistantSuggestion(label: 'More', prompt: 'more')],
  );

  AssistantMessageEntity user(String id) =>
      AssistantMessageEntity(id: id, role: AssistantRole.user, content: id);
  AssistantMessageEntity reply(
    String id, {
    List<AssistantBlock> blocks = const [],
  }) => AssistantMessageEntity(
    id: id,
    role: AssistantRole.assistant,
    blocks: blocks,
  );

  AssistantThread loaded(List<AssistantMessageEntity> messages) =>
      AssistantThread.loaded(conversation: conversation, messages: messages);

  test('loaded threads keep server order, system notices included', () {
    final thread = loaded([
      user('u1'),
      const AssistantMessageEntity(id: 's', role: AssistantRole.system),
      reply('a1'),
    ]);
    expect(thread.entries.map((e) => e.key), ['u1', 's', 'a1']);
    expect(thread.conversationId, 'c1');
  });

  test('N6: a reply with a handoff card hands the thread off', () {
    final thread = loaded([user('u1')]).completeTurn(
      reply(
        'a1',
        blocks: const [
          AssistantHandoffBlock(ticketId: 't9', ticketNumber: 'T-9'),
        ],
      ),
    );
    expect(thread.isHandedOff, isTrue);
    expect(thread.ticketNumber, 'T-9');
    expect(thread.conversation?.supportTicketId, 't9');
    // A plain reply leaves the status alone.
    expect(loaded([]).completeTurn(reply('a2')).isHandedOff, isFalse);
  });

  group('startConversation', () {
    final draft = AssistantMessageEntity.draft(clientKey: 'd1', text: 'hi');

    test('a new chat adopts the id without a divider', () {
      final thread = AssistantThread.empty
          .append(AssistantMessageEntry(draft))
          .startConversation(conversationId: 'c9', draftKey: 'd1', title: 'hi');
      expect(thread.conversationId, 'c9');
      expect(thread.conversation?.title, 'hi');
      expect(thread.entries.map((e) => e.key), ['d1']);
    });

    test('the same id is a no-op', () {
      final thread = loaded([user('u1')]).append(AssistantMessageEntry(draft));
      expect(
        thread.startConversation(conversationId: 'c1', draftKey: 'd1'),
        same(thread),
      );
    });

    test('a different id = the thread was closed: divider above the draft', () {
      final thread = loaded([user('u1'), reply('a1')])
          .append(AssistantMessageEntry(draft))
          .startConversation(conversationId: 'c2', draftKey: 'd1');
      expect(thread.conversationId, 'c2');
      expect(thread.entries.map((e) => e.key), [
        'u1',
        'a1',
        '${AssistantThread.dividerKeyPrefix}c2',
        'd1',
      ]);
      expect(thread.entries[2], isA<AssistantDividerEntry>());
    });
  });

  test('confirmDraft swaps in the server copy under the draft key', () {
    final thread = AssistantThread.empty
        .append(
          AssistantMessageEntry(
            AssistantMessageEntity.draft(clientKey: 'd1', text: 'hi'),
          ),
        )
        .confirmDraft('d1', user('u1'));
    final message = (thread.entries.single as AssistantMessageEntry).message;
    expect(message.id, 'u1');
    expect(message.key, 'd1');
    expect(message.delivery, AssistantDelivery.sent);
  });

  test('markDraft flips a draft to failed and back', () {
    final thread = AssistantThread.empty.append(
      AssistantMessageEntry(
        AssistantMessageEntity.draft(clientKey: 'd1', text: 'hi'),
      ),
    );
    final failed = thread.markDraft('d1', AssistantDelivery.failed);
    expect(
      (failed.entries.single as AssistantMessageEntry).message.delivery,
      AssistantDelivery.failed,
    );
  });

  test('suggestion chips are live only on the LAST row', () {
    final thread = loaded([
      user('u1'),
      reply('a1', blocks: const [chips]),
    ]);
    expect(thread.suggestionsKey, 'a1');
    final afterSend = thread.append(
      AssistantMessageEntry(
        AssistantMessageEntity.draft(clientKey: 'd1', text: 'more'),
      ),
    );
    expect(afterSend.suggestionsKey, isNull);
    expect(loaded([reply('a1')]).suggestionsKey, isNull);
  });

  group('cart proposals', () {
    const summary = AssistantCartSummaryBlock(
      cart: AssistantCartSnapshot(itemCount: 1, totalFils: 1250),
    );

    test('a confirm reply replaces the proposal in place and inserts the '
        'summary right after it', () {
      final thread = loaded([
        user('u1'),
        reply('a1', blocks: [AssistantTextBlock.parse('ok'), pending, chips]),
      ]);
      final confirmed = thread.replaceCartAction('act-1', [
        summary,
        pending.withStatus(AssistantActionStatus.confirmed),
      ]);
      final blocks =
          (confirmed.entries.last as AssistantMessageEntry).message.blocks;
      expect(blocks[1], pending.withStatus(AssistantActionStatus.confirmed));
      expect(blocks[2], summary);
      expect(blocks.last, chips);
      expect(
        confirmed.cartAction('act-1')?.status,
        AssistantActionStatus.confirmed,
      );
    });

    test('a reply without the action still marks it confirmed', () {
      final thread = loaded([
        reply('a1', blocks: const [pending]),
      ]);
      expect(
        thread.replaceCartAction('act-1', const []).cartAction('act-1')?.status,
        AssistantActionStatus.confirmed,
      );
    });

    test('expire reaches proposals kept in a failed reply (L7)', () {
      const failedTurn = AssistantLiveTurn(
        key: 't1',
        prompt: 'add milk',
        userMessageKey: 'd1',
        phase: AssistantTurnPhase.failed,
        cards: [pending],
      );
      final thread = AssistantThread.empty
          .append(const AssistantTurnEntry(failedTurn))
          .expireCartAction('act-1');
      expect(thread.cartAction('act-1')?.status, AssistantActionStatus.expired);
    });

    test('an unknown action id changes nothing', () {
      final thread = loaded([
        reply('a1', blocks: const [pending]),
      ]);
      expect(thread.replaceCartAction('nope', const [summary]), thread);
    });
  });

  test('withFeedback rates one message', () {
    final thread = loaded([reply('a1'), reply('a2')])
        .withFeedback('a2', AssistantFeedback.up);
    expect(thread.messageById('a1')?.feedback, AssistantFeedback.none);
    expect(thread.messageById('a2')?.feedback, AssistantFeedback.up);
  });

  group('handOff', () {
    test('marks the thread handed off and adds the ticket card once', () {
      final thread = loaded([user('u1'), reply('a1')])
          .handOff(ticketId: 't1', ticketNumber: 'T-100');
      expect(thread.isHandedOff, isTrue);
      expect(thread.canHandOff, isFalse);
      expect(thread.ticketNumber, 'T-100');
      expect(thread.conversation?.supportTicketId, 't1');
      expect(thread.entries, hasLength(3));
    });

    test('no second card when the server thread already has it', () {
      final thread = loaded([
        reply(
          'a1',
          blocks: const [
            AssistantHandoffBlock(ticketId: 't1', ticketNumber: 'T-100'),
          ],
        ),
      ]).handOff(ticketId: 't1', ticketNumber: 'T-100');
      expect(thread.entries, hasLength(1));
    });
  });

  test('a lost conversation stops sending to it and ends the chat', () {
    final thread = loaded([user('u1')]).loseConversation();
    expect(thread.conversationId, isNull);
    expect(thread.hasEnded, isTrue);
    expect(thread.canHandOff, isFalse);
  });

  test('a closed conversation has ended', () {
    final thread = AssistantThread.loaded(
      conversation: conversation.copyWith(
        status: AssistantConversationStatus.closed,
      ),
      messages: const [],
    );
    expect(thread.hasEnded, isTrue);
  });
}
