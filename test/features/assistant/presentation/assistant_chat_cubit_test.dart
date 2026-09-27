import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_action_result.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_block.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_cart_snapshot.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_conversation_entity.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_error_code.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_handoff_ticket.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_live_turn.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_message_entity.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_stream_event.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_thread.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_chat_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_chat_state.dart';

import 'assistant_test_fakes.dart';

void main() {
  late FakeAssistantRepository repository;
  late AssistantChatCubit cubit;

  setUp(() {
    repository = FakeAssistantRepository();
    cubit = chatCubit(repository);
  });
  tearDown(() => cubit.close());

  List<String> keysOf(AssistantThread thread) =>
      thread.entries.map((entry) => entry.key).toList();

  AssistantTurnEntry lastTurnEntry() =>
      cubit.state.thread.entries.last as AssistantTurnEntry;

  AssistantMessageEntity lastMessage() =>
      (cubit.state.thread.entries.last as AssistantMessageEntry).message;

  group('open', () {
    test('a new chat asks for the latest thread only (limit 1) and offers '
        'to continue it when it is still active', () async {
      final opening = cubit.open();
      expect(cubit.state.isWelcome, isTrue);
      expect(repository.lists.single.args, (page: 1, limit: 1));
      repository.lists.single.open(
        Right(feedOf(const [AssistantConversationEntity(id: 'c9')])),
      );
      await opening;
      expect(cubit.state.resumable?.id, 'c9');
    });

    test('a failed or closed latest thread offers nothing, silently', () async {
      final failing = cubit.open();
      repository.lists.single.open(const Left(NetworkFailure()));
      await failing;
      expect(cubit.state.resumable, isNull);
      expect(cubit.state.failure, isNull);
      expect(cubit.state.status, AssistantChatStatus.ready);
    });

    test('an initial prompt is sent at once (no history request)', () async {
      await cubit.open(initialPrompt: 'Tell me about Lurpak butter');
      expect(repository.lists, isEmpty);
      expect(repository.sends.single.message, 'Tell me about Lurpak butter');
    });

    test('a conversation id loads that thread: loading → ready', () async {
      final loading = cubit.open(conversationId: 'c1');
      expect(cubit.state.status, AssistantChatStatus.loading);
      final thread = threadOf([userMessage('u1', 'hi')]);
      repository.threads.single.open(Right(thread));
      await loading;
      expect(cubit.state.status, AssistantChatStatus.ready);
      expect(cubit.state.thread, thread);
    });

    test('thread failures: 401 → sign-in, 404 → a new chat + notice, '
        'others → error with retry', () async {
      final signedOut = cubit.loadThread('c1');
      repository.threads.last.open(const Left(UnauthorizedFailure()));
      await signedOut;
      expect(cubit.state.status, AssistantChatStatus.signedOut);

      final gone = cubit.loadThread('c1');
      repository.threads.last.open(const Left(NotFoundFailure('gone')));
      await gone;
      expect(cubit.state.status, AssistantChatStatus.ready);
      expect(cubit.state.isWelcome, isTrue);
      expect(cubit.state.notice, AssistantChatNotice.conversationUnavailable);

      final offline = cubit.loadThread('c1');
      repository.threads.last.open(const Left(NetworkFailure()));
      await offline;
      expect(cubit.state.status, AssistantChatStatus.error);
      expect(cubit.state.failure, const NetworkFailure());

      final retry = cubit.retryLoad();
      expect(repository.threads.last.args, 'c1');
      repository.threads.last.open(Right(threadOf(const [])));
      await retry;
      expect(cubit.state.status, AssistantChatStatus.ready);
    });

    test('a thread read that a newer one replaced is dropped', () async {
      final first = cubit.loadThread('c1');
      final second = cubit.loadThread('c2');
      repository.threads[1].open(Right(threadOf(const [], id: 'c2')));
      await second;
      repository.threads[0].open(Right(threadOf(const [], id: 'c1')));
      await first;
      expect(cubit.state.thread.conversationId, 'c2');
    });
  });

  group('a turn', () {
    test('streams: optimistic bubble → thinking → tool → cards → words → '
        'the stored reply in place, keyed as the live turn', () async {
      expect(cubit.send('  Show me butter  '), isTrue);
      final draft = lastMessage();
      expect(draft.content, 'Show me butter');
      expect(draft.delivery, AssistantDelivery.sending);
      expect(cubit.state.liveTurn?.phase, AssistantTurnPhase.thinking);
      expect(repository.lastSend.conversationId, isNull);

      final turn = repository.lastSend..accept();
      await settle();
      expect(cubit.state.thread.conversationId, 'c1');
      expect(lastMessage().id, 'u1');
      expect(lastMessage().key, draft.key, reason: 'same row, no re-animation');

      turn
        ..add(
          const AssistantStreamToolStarted(
            name: 'search_products',
            callId: 'a',
          ),
        )
        ..add(
          const AssistantStreamToolFinished(
            name: 'search_products',
            callId: 'a',
          ),
        );
      await settle();
      expect(cubit.state.liveTurn?.activeToolName, 'search_products');

      const products = AssistantProductsBlock(products: []);
      turn.add(const AssistantStreamBlock(block: pendingProposal));
      turn
        ..add(const AssistantStreamTextDelta(delta: 'Here '))
        ..add(const AssistantStreamTextDelta(delta: 'you go'));
      await settle();
      expect(cubit.state.liveTurn?.cards, const [pendingProposal]);
      expect(cubit.state.isStreaming, isTrue);
      expect(cubit.send('again'), isFalse, reason: 'one turn at a time');

      final liveKey = cubit.state.liveTurn!.key;
      turn.complete(
        assistantReply(
          'a1',
          'Here you go',
          blocks: const [pendingProposal, products],
        ),
      );
      await settle();
      expect(cubit.state.liveTurn, isNull);
      expect(cubit.state.isStreaming, isFalse);
      expect(lastMessage().id, 'a1');
      expect(lastMessage().key, liveKey);
      expect(keysOf(cubit.state.thread), [draft.key, liveKey]);
      expect(turn.cancelled, isTrue, reason: 'subscription released');
      expect(repository.sends, hasLength(1));
    });

    test('a double send while streaming is ignored', () async {
      cubit.send('one');
      cubit.send('two');
      expect(repository.sends, hasLength(1));
      expect(cubit.state.thread.entries, hasLength(1));
    });

    test('empty and over-limit prompts never leave', () {
      expect(cubit.send('   '), isFalse);
      expect(cubit.send('x' * 2001), isFalse);
      expect(repository.sends, isEmpty);
    });

    test(
      'a burst of 100 deltas is drawn in 2 emits (leading + one flush)',
      () async {
        cubit.send('long answer please');
        final turn = repository.lastSend..accept();
        await settle();
        final emitted = <AssistantChatState>[];
        final listening = cubit.stream.listen(emitted.add);
        for (var i = 0; i < 100; i++) {
          turn.add(AssistantStreamTextDelta(delta: 'w$i '));
        }
        await Future<void>.delayed(AssistantChatCubit.streamFlushInterval * 3);
        expect(emitted, hasLength(2));
        expect(
          cubit.state.liveTurn!.text.split(' ').where((w) => w.isNotEmpty),
          hasLength(100),
        );
        // Any other frame flushes the words first, then applies itself.
        turn
          ..add(const AssistantStreamTextDelta(delta: 'tail '))
          ..add(const AssistantStreamBlock(block: pendingProposal));
        await settle();
        expect(cubit.state.liveTurn!.text, endsWith('tail '));
        expect(cubit.state.liveTurn!.cards, const [pendingProposal]);
        await listening.cancel();
      },
    );

    test('100 deltas spread over time: at most one emit per flush interval '
        '(≤ 20 a second)', () async {
      cubit.send('long answer please');
      final turn = repository.lastSend..accept();
      await settle();
      final emitted = <AssistantChatState>[];
      final listening = cubit.stream.listen(emitted.add);
      final clock = Stopwatch()..start();
      for (var i = 0; i < 100; i++) {
        turn.add(AssistantStreamTextDelta(delta: 'w$i '));
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      await Future<void>.delayed(AssistantChatCubit.streamFlushInterval * 2);
      clock.stop();
      final intervals =
          clock.elapsedMilliseconds /
          AssistantChatCubit.streamFlushInterval.inMilliseconds;
      expect(emitted.length, lessThanOrEqualTo(intervals.ceil() + 1));
      expect(emitted.length, lessThan(100));
      await listening.cancel();
    });

    test('Stop cancels the request and keeps the partial reply', () async {
      cubit.send('hi');
      final turn = repository.lastSend
        ..accept()
        ..add(const AssistantStreamTextDelta(delta: 'Half an ans'));
      await settle();
      cubit.stop();
      expect(turn.cancelled, isTrue);
      expect(cubit.state.liveTurn, isNull);
      final stopped = lastTurnEntry().turn;
      expect(stopped.isStopped, isTrue);
      expect(stopped.richText.plainText, 'Half an ans');
    });

    test('a drop mid-stream keeps what streamed and never re-sends', () async {
      cubit.send('hi');
      repository.lastSend
        ..accept()
        ..add(const AssistantStreamBlock(block: pendingProposal))
        ..fail(const NetworkFailure());
      await settle();
      final failed = lastTurnEntry().turn;
      expect(failed.isFailed, isTrue);
      expect(failed.failure, const NetworkFailure());
      expect(failed.cards, const [pendingProposal]);
      expect(cubit.state.notice, AssistantChatNotice.turnFailed);
      expect(repository.sends, hasLength(1));
    });

    test('a stream that closes without a terminal frame is a drop', () async {
      cubit.send('hi');
      final turn = repository.lastSend..accept();
      await turn.close();
      await settle();
      expect(lastTurnEntry().turn.failure, const NetworkFailure());
    });

    test('pre-stream failures leave an unsent bubble; Retry resends it '
        'under the same key', () async {
      cubit.send('hi');
      final draftKey = cubit.state.thread.lastKey!;
      repository.lastSend.fail(
        const ServerFailure(
          'Invalid',
          statusCode: 400,
          code: 'VALIDATION_ERROR',
        ),
      );
      await settle();
      expect(cubit.state.liveTurn, isNull);
      expect(lastMessage().delivery, AssistantDelivery.failed);
      expect(cubit.state.failedAction, AssistantChatAction.send);

      cubit.retryDraft(draftKey);
      expect(repository.sends, hasLength(2));
      expect(repository.lastSend.message, 'hi');
      expect(lastMessage().delivery, AssistantDelivery.sending);
      expect(cubit.state.liveTurn?.userMessageKey, draftKey);
      expect(cubit.state.thread.entries, hasLength(1));
    });

    test('a pre-stream 401 opens the sign-in prompt', () async {
      cubit.send('hi');
      repository.lastSend.fail(const UnauthorizedFailure());
      await settle();
      expect(cubit.state.status, AssistantChatStatus.signedOut);
      expect(cubit.send('again'), isFalse);
    });

    test('L7: cards streamed then a terminal error: the reply stays with '
        'its proposal; confirming it 404s → expired', () async {
      cubit.send('Add 2 Lurpak butter to my cart');
      repository.lastSend
        ..accept()
        ..add(const AssistantStreamBlock(block: pendingProposal))
        ..add(const AssistantStreamTextDelta(delta: 'I added 2 pieces'))
        ..add(
          const AssistantStreamFailed(
            code: AssistantErrorCode.internalError,
            message: 'Document failed validation',
          ),
        );
      await settle();
      final failed = lastTurnEntry().turn;
      expect(failed.isFailed, isTrue);
      expect(failed.displayErrorMessage, isNull, reason: 'N4: raw English');
      expect(failed.richText.plainText, 'I added 2 pieces');
      expect(cubit.state.thread.cartAction('act-1'), pendingProposal);

      final confirming = cubit.confirmAction('act-1');
      repository.confirms.single.open(
        const Left(NotFoundFailure('Action not found')),
      );
      await confirming;
      expect(
        cubit.state.thread.cartAction('act-1')?.status,
        AssistantActionStatus.expired,
      );
      expect(cubit.state.notice, AssistantChatNotice.actionExpired);
    });

    test('Retry after a failed reply answers the same bubble again', () async {
      cubit.send('hi');
      repository.lastSend
        ..accept()
        ..add(const AssistantStreamFailed(code: 'X', message: 'boom'));
      await settle();
      final failedKey = lastTurnEntry().key;
      cubit.retryTurn(failedKey);
      expect(repository.sends, hasLength(2));
      expect(keysOf(cubit.state.thread), isNot(contains(failedKey)));
      expect(cubit.state.liveTurn?.userMessageKey, cubit.state.thread.lastKey);
      expect(repository.lastSend.conversationId, 'c1');
    });

    test('L9: an unknown conversation ends the chat (no Retry)', () async {
      final loading = cubit.loadThread('c-old');
      repository.threads.single.open(Right(threadOf(const [], id: 'c-old')));
      await loading;
      cubit.send('hi');
      expect(repository.lastSend.conversationId, 'c-old');
      repository.lastSend.add(
        const AssistantStreamFailed(
          code: AssistantErrorCode.resourceNotFound,
          message: 'Conversation not found',
        ),
      );
      await settle();
      expect(cubit.state.thread.conversationLost, isTrue);
      expect(cubit.state.thread.hasEnded, isTrue);
      expect(cubit.state.canSend, isFalse);
      expect(lastMessage().delivery, AssistantDelivery.failed);
      expect(cubit.state.notice, AssistantChatNotice.conversationUnavailable);
      cubit.startNewChat();
      expect(cubit.state.isWelcome, isTrue);
      expect(cubit.state.canSend, isTrue);
    });

    test('a closed thread: message_start carries a new id → a divider above '
        'the bubble, and the chat continues there', () async {
      final loading = cubit.loadThread('c1');
      repository.threads.single.open(
        Right(
          threadOf([userMessage('u0', 'old'), assistantReply('a0', 'old')]),
        ),
      );
      await loading;
      cubit.send('hi');
      repository.lastSend.accept(conversationId: 'c2', userId: 'u1');
      await settle();
      expect(cubit.state.thread.conversationId, 'c2');
      final keys = keysOf(cubit.state.thread);
      expect(keys[2], '${AssistantThread.dividerKeyPrefix}c2');
      expect(keys, hasLength(4));
    });
  });

  group('cart proposals', () {
    Future<void> loadProposal() async {
      final loading = cubit.loadThread('c1');
      repository.threads.single.open(
        Right(
          threadOf([
            assistantReply('a1', 'ok', blocks: const [pendingProposal]),
          ]),
        ),
      );
      await loading;
    }

    test('a double tap confirms once; success swaps the card in place, adds '
        'the cart snapshot after it and bumps cartRevision', () async {
      await loadProposal();
      final first = cubit.confirmAction('act-1');
      final second = cubit.confirmAction('act-1');
      expect(repository.confirms, hasLength(1));
      expect(cubit.state.confirmingActionIds, {'act-1'});
      const summary = AssistantCartSummaryBlock(
        cart: AssistantCartSnapshot(itemCount: 2, totalFils: 1798),
      );
      repository.confirms.single.open(
        Right(
          AssistantActionResult(
            message: 'Added to your cart',
            blocks: [
              summary,
              pendingProposal.withStatus(AssistantActionStatus.confirmed),
            ],
          ),
        ),
      );
      await Future.wait([first, second]);
      expect(cubit.state.confirmingActionIds, isEmpty);
      expect(cubit.state.cartRevision, 1);
      expect(cubit.state.actionMessages, {'act-1': 'Added to your cart'});
      expect(lastMessage().blocks.skip(1), [
        pendingProposal.withStatus(AssistantActionStatus.confirmed),
        summary,
      ]);
      // Confirmed: a later tap sends nothing.
      await cubit.confirmAction('act-1');
      expect(repository.confirms, hasLength(1));
    });

    test('other failures keep the proposal pending (snack bar)', () async {
      await loadProposal();
      final confirming = cubit.confirmAction('act-1');
      repository.confirms.single.open(const Left(NetworkFailure()));
      await confirming;
      expect(cubit.state.thread.cartAction('act-1')?.isPending, isTrue);
      expect(cubit.state.failedAction, AssistantChatAction.confirm);
      expect(cubit.state.cartRevision, 0);
    });

    test('a proposal still streaming cannot be confirmed yet', () async {
      cubit.send('add butter');
      repository.lastSend
        ..accept()
        ..add(const AssistantStreamBlock(block: pendingProposal));
      await settle();
      await cubit.confirmAction('act-1');
      expect(repository.confirms, isEmpty);
    });
  });

  group('thumbs', () {
    Future<void> loadReply({
      AssistantFeedback feedback = AssistantFeedback.none,
    }) async {
      final loading = cubit.loadThread('c1');
      repository.threads.single.open(
        Right(threadOf([assistantReply('a1', 'ok', feedback: feedback)])),
      );
      await loading;
    }

    test('optimistic; a refusal rolls back to what the server has', () async {
      await loadReply();
      final rating = cubit.rate('a1', AssistantFeedback.up);
      expect(lastMessage().feedback, AssistantFeedback.up);
      repository.ratings.single.open(const Left(NetworkFailure()));
      await rating;
      expect(lastMessage().feedback, AssistantFeedback.none);
      expect(cubit.state.failedAction, AssistantChatAction.rate);
    });

    test('tapping the active thumb clears it (null on the wire)', () async {
      await loadReply(feedback: AssistantFeedback.down);
      final rating = cubit.rate('a1', AssistantFeedback.down);
      expect(lastMessage().feedback, AssistantFeedback.none);
      expect(repository.ratings.single.args, (
        messageId: 'a1',
        feedback: AssistantFeedback.none,
      ));
      repository.ratings.single.open(const Right(unit));
      await rating;
      expect(cubit.state.notice, isNull, reason: 'clearing is not thanked');
    });

    test('one request in flight; the last tap wins', () async {
      await loadReply();
      final first = cubit.rate('a1', AssistantFeedback.up);
      unawaited(cubit.rate('a1', AssistantFeedback.down));
      expect(repository.ratings, hasLength(1));
      expect(lastMessage().feedback, AssistantFeedback.down);
      repository.ratings.first.open(const Right(unit));
      await settle();
      expect(repository.ratings, hasLength(2));
      expect(repository.ratings.last.args, (
        messageId: 'a1',
        feedback: AssistantFeedback.down,
      ));
      repository.ratings.last.open(const Right(unit));
      await first;
      expect(lastMessage().feedback, AssistantFeedback.down);
    });

    test('a burst that ends where the server is sends nothing more', () async {
      await loadReply();
      final first = cubit.rate('a1', AssistantFeedback.up);
      unawaited(cubit.rate('a1', AssistantFeedback.up)); // off again
      unawaited(cubit.rate('a1', AssistantFeedback.up)); // on again
      repository.ratings.single.open(const Right(unit));
      await first;
      expect(repository.ratings, hasLength(1));
      expect(cubit.state.notice, AssistantChatNotice.feedbackSent);
    });

    test('unsaved replies and user messages cannot be rated', () async {
      final loading = cubit.loadThread('c1');
      repository.threads.single.open(
        Right(threadOf([userMessage('u1', 'hi')])),
      );
      await loading;
      await cubit.rate('u1', AssistantFeedback.up);
      expect(repository.ratings, isEmpty);
    });
  });

  group('handoff', () {
    test('one request for a double tap; success hands the thread off and '
        'adds the ticket card', () async {
      final loading = cubit.loadThread('c1');
      repository.threads.single.open(
        Right(threadOf([userMessage('u1', 'hi')])),
      );
      await loading;
      expect(cubit.state.canHandOff, isTrue);
      final first = cubit.handOff();
      final second = cubit.handOff();
      expect(repository.handoffs, hasLength(1));
      expect(cubit.state.isHandingOff, isTrue);
      repository.handoffs.single.open(
        const Right(
          AssistantHandoffTicket(
            ticketId: 't1',
            ticketNumber: 'T-1001',
            message: 'A person will reply here',
          ),
        ),
      );
      await Future.wait([first, second]);
      expect(cubit.state.thread.isHandedOff, isTrue);
      expect(cubit.state.thread.ticketNumber, 'T-1001');
      expect(cubit.state.notice, AssistantChatNotice.handedOff);
      expect(cubit.state.noticeMessage, 'A person will reply here');
      expect(cubit.state.canHandOff, isFalse);
    });

    test('nothing to hand off in a new chat', () async {
      await cubit.handOff();
      expect(repository.handoffs, isEmpty);
    });
  });

  group('locale', () {
    test('the reload waits for the reply streaming now', () async {
      final loading = cubit.loadThread('c1');
      repository.threads.single.open(Right(threadOf(const [])));
      await loading;
      cubit.send('hi');
      await cubit.reloadForLocale();
      expect(repository.threads, hasLength(1));
      repository.lastSend
        ..accept()
        ..complete(assistantReply('a1', 'done'));
      await settle();
      expect(repository.threads, hasLength(2));
      expect(repository.threads.last.args, 'c1');
      expect(cubit.state.status, AssistantChatStatus.ready);
    });

    test('a new chat has nothing to reload', () async {
      await cubit.reloadForLocale();
      expect(repository.threads, isEmpty);
    });
  });

  test('closing the page mid-reply cancels the request', () async {
    cubit.send('hi');
    final turn = repository.lastSend..accept();
    await settle();
    await cubit.close();
    expect(turn.cancelled, isTrue);
  });

  test('a new chat keeps the one just left as "continue"', () async {
    final loading = cubit.loadThread('c1');
    repository.threads.single.open(Right(threadOf([userMessage('u1', 'hi')])));
    await loading;
    cubit.startNewChat();
    expect(cubit.state.isWelcome, isTrue);
    expect(cubit.state.resumable?.id, 'c1');
  });
}
