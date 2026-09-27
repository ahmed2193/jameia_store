import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_block.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_error_code.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_live_turn.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_message_entity.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_rich_text.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_stream_event.dart';

void main() {
  const product = CatalogProductEntity(id: 'p1', slug: 'milk', name: 'Milk');
  const products = AssistantProductsBlock(products: [product]);
  const cartAction = AssistantCartActionBlock(
    actionId: 'act-1',
    items: [AssistantCartActionItem(productId: 'p1', quantity: 2)],
  );
  const chips = AssistantActionsBlock(
    suggestions: [AssistantSuggestion(label: 'More', prompt: 'Show more')],
  );

  AssistantLiveTurn start() => const AssistantLiveTurn(
    key: 'turn-1',
    prompt: 'milk',
    userMessageKey: 'draft-1',
  );

  AssistantLiveTurn fold(List<AssistantStreamEvent> events) =>
      events.fold(start(), (turn, event) => turn.apply(event));

  AssistantMessageEntity stored(String text, List<AssistantBlock> blocks) =>
      AssistantMessageEntity(
        id: 'm2',
        role: AssistantRole.assistant,
        conversationId: 'c1',
        content: text,
        richText: AssistantRichText.parse(text),
        blocks: blocks,
      );

  test('starts thinking with the typing indicator', () {
    final turn = start();
    expect(turn.phase, AssistantTurnPhase.thinking);
    expect(turn.showsTypingIndicator, isTrue);
    expect(turn.isActive, isTrue);
  });

  test('message_start + user_message change nothing on the reply', () {
    final turn = fold([
      const AssistantStreamStarted(conversationId: 'c1'),
      AssistantStreamUserMessage(
        conversationId: 'c1',
        message: const AssistantMessageEntity(
          id: 'u1',
          role: AssistantRole.user,
        ),
      ),
    ]);
    expect(turn, start());
  });

  test('tool status shows the latest RUNNING tool; ok:false is silent', () {
    var turn = fold([
      const AssistantStreamToolStarted(name: 'search_products', callId: 'a'),
      const AssistantStreamToolStarted(name: 'check_delivery', callId: 'b'),
    ]);
    expect(turn.activeToolName, 'check_delivery');
    turn = turn.apply(
      const AssistantStreamToolFinished(
        name: 'check_delivery',
        callId: 'b',
        ok: false,
      ),
    );
    expect(turn.activeToolName, 'search_products');
    expect(turn.isFailed, isFalse);
    turn = turn.apply(
      const AssistantStreamToolFinished(name: 'search_products', callId: 'a'),
    );
    // N1: live tools end within milliseconds — the label of the last one
    // stays up until the text starts.
    expect(turn.activeToolName, 'check_delivery');
    // A partial first word is not drawn yet: the label stays.
    expect(turn.appendText('Hi').activeToolName, 'check_delivery');
    expect(turn.appendText('Hi ').activeToolName, isNull);
    expect(turn.stop().activeToolName, isNull);
    // A repeated tool_start for the same call is not listed twice.
    turn = turn
        .apply(const AssistantStreamToolStarted(name: 'x', callId: 'c'))
        .apply(const AssistantStreamToolStarted(name: 'x', callId: 'c'));
    expect(turn.tools, hasLength(1));
  });

  test('deltas grow the text and flip thinking → streaming', () {
    final turn = fold([
      const AssistantStreamTextDelta(delta: 'Hello'),
      const AssistantStreamTextDelta(delta: ' **there** '),
    ]);
    expect(turn.phase, AssistantTurnPhase.streaming);
    expect(turn.text, 'Hello **there** ');
    expect(turn.richText.plainText, 'Hello there');
    expect(turn.showsTypingIndicator, isFalse);
  });

  test('only complete words are drawn while streaming (Arabic shaping)', () {
    // Live AR deltas split words: "اقت" + "راح".
    var turn = fold([const AssistantStreamTextDelta(delta: 'تم اقت')]);
    expect(turn.text, 'تم اقت');
    expect(turn.richText.plainText, 'تم');
    turn = turn.appendText('راح ');
    expect(turn.richText.plainText, 'تم اقتراح');
    // A single word with no space yet draws nothing (the dots stay).
    final first = fold([const AssistantStreamTextDelta(delta: 'Hel')]);
    expect(first.richText.isEmpty, isTrue);
    expect(first.showsTypingIndicator, isTrue);
    // The whole text shows once the turn ends — any way it ends.
    expect(first.stop().richText.plainText, 'Hel');
    expect(first.drop(const NetworkFailure()).richText.plainText, 'Hel');
    expect(
      first.apply(const AssistantStreamFailed(code: 'X')).richText.plainText,
      'Hel',
    );
  });

  test('adjacent product rails merge (N8); duplicates dropped', () {
    const eggs = CatalogProductEntity(id: 'p2', slug: 'eggs', name: 'Eggs');
    final turn = fold([
      const AssistantStreamBlock(block: products),
      const AssistantStreamBlock(
        block: AssistantProductsBlock(products: [eggs, product]),
      ),
      const AssistantStreamBlock(block: cartAction),
      const AssistantStreamBlock(block: products),
    ]);
    expect(turn.cards, const [
      AssistantProductsBlock(products: [product, eggs]),
      cartAction,
      products,
    ]);
  });

  test('L4: cards stream BEFORE the text and stay under it', () {
    final turn = fold([
      const AssistantStreamToolStarted(name: 'search_products', callId: 'a'),
      const AssistantStreamToolFinished(name: 'search_products', callId: 'a'),
      const AssistantStreamBlock(block: products),
      const AssistantStreamTextDelta(delta: 'Here you go'),
    ]);
    expect(turn.cards, [products]);
    expect(turn.text, 'Here you go');
    // Cards before any text keep the typing dots up.
    final early = fold([const AssistantStreamBlock(block: products)]);
    expect(early.showsTypingIndicator, isTrue);
    expect(early.cards, [products]);
  });

  test(
    'L5/L6: live text and chip blocks are not drawn; empty cards hidden',
    () {
      final turn = fold([
        AssistantStreamBlock(block: AssistantTextBlock.parse('dup')),
        const AssistantStreamBlock(block: chips),
        const AssistantStreamBlock(block: AssistantDeliveryInfoBlock()),
        const AssistantStreamBlock(block: products),
      ]);
      expect(turn.cards, [products]);
      expect(turn.text, isEmpty);
    },
  );

  test('message_end completes with the stored message under the turn key', () {
    final message = stored('Here you go', const [products, chips]);
    final turn = fold([
      const AssistantStreamBlock(block: products),
      const AssistantStreamTextDelta(delta: 'Here you go'),
      AssistantStreamCompleted(conversationId: 'c1', message: message),
    ]);
    expect(turn.phase, AssistantTurnPhase.completed);
    expect(turn.message?.clientKey, 'turn-1');
    expect(turn.message?.key, 'turn-1');
    expect(turn.message?.suggestions.single.prompt, 'Show more');
    // L6: once complete, the turn draws exactly the stored text.
    expect(turn.message?.richText, turn.richText);
    expect(turn.tools, isEmpty);
  });

  test('L7: a terminal error keeps the streamed cards and text', () {
    final turn = fold([
      const AssistantStreamToolStarted(name: 'add_to_cart', callId: 'a'),
      const AssistantStreamBlock(block: cartAction),
      const AssistantStreamTextDelta(delta: 'Added'),
      const AssistantStreamFailed(
        code: AssistantErrorCode.internalError,
        message: 'Document failed validation',
      ),
    ]);
    expect(turn.isFailed, isTrue);
    expect(turn.cards, [cartAction]);
    expect(turn.text, 'Added');
    expect(turn.errorMessage, 'Document failed validation');
    // N4: the raw English INTERNAL_ERROR text is never shown.
    expect(turn.displayErrorMessage, isNull);
    expect(turn.tools, isEmpty);
    expect(turn.lostConversation, isFalse);
  });

  test('other in-band errors are shown as sent; empty → generic', () {
    expect(
      fold([
        const AssistantStreamFailed(code: 'RATE_LIMITED', message: 'Slow down'),
      ]).displayErrorMessage,
      'Slow down',
    );
    expect(
      fold([const AssistantStreamFailed(code: 'X')]).displayErrorMessage,
      isNull,
    );
  });

  test('L9: RESOURCE_NOT_FOUND means the conversation is gone', () {
    final turn = fold([
      const AssistantStreamFailed(
        code: AssistantErrorCode.resourceNotFound,
        message: 'Conversation not found',
      ),
    ]);
    expect(turn.lostConversation, isTrue);
  });

  test('nothing applies after a terminal event', () {
    final failed = fold([
      const AssistantStreamFailed(code: 'X'),
      const AssistantStreamTextDelta(delta: 'late'),
      const AssistantStreamBlock(block: products),
    ]);
    expect(failed.text, isEmpty);
    expect(failed.cards, isEmpty);
  });

  test('stop keeps the partial text; drop records the transport failure', () {
    final partial = fold([const AssistantStreamTextDelta(delta: 'Half')]);
    final stopped = partial.stop();
    expect(stopped.isStopped, isTrue);
    expect(stopped.text, 'Half');
    expect(stopped.stop(), stopped);
    expect(stopped.apply(const AssistantStreamTextDelta(delta: '!')), stopped);

    final dropped = partial.drop(const NetworkFailure());
    expect(dropped.isFailed, isTrue);
    expect(dropped.failure, const NetworkFailure());
    expect(dropped.text, 'Half');
  });

  test('an empty delta changes nothing', () {
    expect(start().appendText(''), start());
  });
}
