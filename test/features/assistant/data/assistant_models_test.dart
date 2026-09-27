import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/offer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/network/event_stream_client.dart';
import 'package:hero_mart/src/features/assistant/data/mappers/assistant_block_mapper.dart';
import 'package:hero_mart/src/features/assistant/data/mappers/assistant_message_mapper.dart';
import 'package:hero_mart/src/features/assistant/data/models/assistant_block_model.dart';
import 'package:hero_mart/src/features/assistant/data/models/assistant_conversation_model.dart';
import 'package:hero_mart/src/features/assistant/data/models/assistant_reply_models.dart';
import 'package:hero_mart/src/features/assistant/data/models/assistant_stream_event_model.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_block.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_conversation_entity.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_live_turn.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_message_entity.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_stream_event.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_thread.dart';

import '../assistant_fixtures.dart';

List<AssistantStreamEvent> _events(String turn) => [
  for (final frame in AssistantFixtures.liveFrames(turn))
    if (AssistantStreamEventModel.fromFrame(frame) case final model?)
      model.toEntity(),
];

AssistantLiveTurn _fold(List<AssistantStreamEvent> events) => events.fold(
  const AssistantLiveTurn(key: 't', prompt: 'p', userMessageKey: 'u'),
  (turn, event) => turn.apply(event),
);

void main() {
  group('every block kind (mock_blocks.json)', () {
    late List<AssistantBlock> blocks;

    setUpAll(() {
      blocks = AssistantBlockModel.listFrom(AssistantFixtures.mockBlocks())
          .toEntities();
    });

    test('unknown kinds, malformed cards and non-objects are skipped; the '
        'rest keeps its order', () {
      expect(blocks.map((b) => b.runtimeType), [
        AssistantTextBlock,
        AssistantProductsBlock,
        AssistantProductDetailBlock,
        AssistantCartActionBlock,
        AssistantCartSummaryBlock,
        AssistantOrderBlock,
        AssistantOrderBlock,
        AssistantOffersBlock,
        AssistantRecipeBlock,
        AssistantFaqBlock,
        AssistantCategoriesBlock,
        AssistantBrandsBlock,
        AssistantDeliverySlotsBlock,
        AssistantDeliveryInfoBlock,
        AssistantDeliveryInfoBlock,
        AssistantLocationsBlock,
        AssistantHandoffBlock,
        AssistantErrorBlock,
        AssistantActionsBlock,
      ]);
    });

    T only<T>() => blocks.whereType<T>().first;

    test('text is parsed once into rich text', () {
      final text = only<AssistantTextBlock>();
      expect(text.richText.blocks.first.runs[1].text, 'what I found');
      expect(text.richText.blocks.first.runs[1].bold, isTrue);
      expect(text.richText.blocks.last.marker, '2.');
    });

    test('products: bad rows dropped, tag ids filtered (L18), variant has '
        'no quick add (L19), stock 0 is out of stock', () {
      final products = only<AssistantProductsBlock>().products;
      expect(products, hasLength(3));
      expect(products[0].tags, ['best-seller']);
      expect(products[0].proPriceFils, 2100);
      expect(products[1].isVariant, isTrue);
      expect(products[1].canQuickAdd, isFalse);
      expect(products[1].image, '');
      expect(products[2].inStock, isFalse);
    });

    test('cart_action: a broken nested product keeps the line; a line without '
        'productId is dropped; estimatedTotal read', () {
      final action = only<AssistantCartActionBlock>();
      expect(action.actionId, 'a059e104bf1e645249a95219');
      expect(action.status, AssistantActionStatus.pending);
      expect(action.estimatedTotalFils, 4500);
      expect(action.items, hasLength(2));
      expect(action.items[0].product?.name, 'Lurpak Butter 200g');
      expect(action.items[1].product, isNull);
      expect(action.items[1].variantId, 'v-1l');
    });

    test('cart_summary: only the card fields, ≤ 4 previews', () {
      final cart = only<AssistantCartSummaryBlock>().cart;
      expect(cart.itemCount, 5);
      expect(cart.totalFils, 5150);
      expect(cart.minOrderFils, 2500);
      expect(cart.meetsMinOrder, isTrue);
      expect(cart.previews.map((p) => p.name), [
        'Butter',
        'Milk',
        'Eggs',
        'Bread',
      ]);
      expect(cart.previews[1].imageUrl, '');
    });

    test('order / order_status: core status decode, null thumbnails dropped, '
        'unknown status → other', () {
      final orders = blocks.whereType<AssistantOrderBlock>().toList();
      expect(orders[0].order.id, '6ab0000000000000000000a1');
      expect(orders[0].order.status, OrderStatus.outForDelivery);
      expect(orders[0].order.thumbnails, hasLength(2));
      expect(orders[0].isStatusUpdate, isFalse);
      expect(orders[1].isStatusUpdate, isTrue);
      expect(orders[1].order.status, OrderStatus.other);
      expect(orders[1].order.createdAt, isNull);
    });

    test('offers map onto the core OfferEntity; coupon kept', () {
      final offers = only<AssistantOffersBlock>();
      expect(offers.couponCode, 'SAVE10');
      expect(offers.offers.first.rewardType, OfferRewardType.freeDelivery);
      expect(offers.offers.first.minSubtotalFils, 5000);
      expect(offers.offers.last.percent, 10);
      expect(offers.offers.last.maxDiscountFils, 3000);
      expect(offers.offers.last.description, '');
      expect(offers.offers.last.endsAt, isNotNull);
    });

    test('recipe: block servings differ from the recipe default', () {
      final recipe = only<AssistantRecipeBlock>();
      expect(recipe.servings, 1);
      expect(recipe.recipe.servings, 2);
      expect(recipe.ingredientCount, 4);
      expect(recipe.recipe.cuisineName, 'Kuwaiti');
    });

    test('faq, categories, brands, locations', () {
      final faq = only<AssistantFaqBlock>();
      expect(faq.items, hasLength(2));
      expect(faq.items[1].id, 'Payment?');
      expect(only<AssistantCategoriesBlock>().categories.single.slug, 'dairy');
      expect(only<AssistantBrandsBlock>().brands.single.name, 'Lurpak');
      final location = only<AssistantLocationsBlock>().items.single;
      expect(location.position.lat, 29.33);
      expect(location.hasPhone, isTrue);
    });

    test('delivery_slots map onto the core slot entities', () {
      final days = only<AssistantDeliverySlotsBlock>().days;
      expect(days, hasLength(2));
      expect(days[0].slots.first.isBookable, isFalse);
      expect(days[0].slots.last.isBookable, isTrue);
      expect(days[1].hasNamedLabel, isFalse);
    });

    test('delivery_info: fee 0 is a value; an empty block is hidden (L13)', () {
      final infos = blocks.whereType<AssistantDeliveryInfoBlock>().toList();
      expect(infos[0].feeFils, 0);
      expect(infos[0].isVisible, isTrue);
      expect(infos[1].isVisible, isFalse);
    });

    test('handoff, error and actions', () {
      expect(only<AssistantHandoffBlock>().ticketNumber, 'T-2026-0042');
      expect(only<AssistantErrorBlock>().message, isNull);
      expect(
        only<AssistantActionsBlock>().suggestions.single.prompt,
        'Show me more breakfast items',
      );
    });
  });

  group('live turns (api.jm3eia.store, 2026-09-24)', () {
    test('every frame of every captured turn parses', () {
      for (final turn in AssistantFixtures.liveTurns) {
        final frames = AssistantFixtures.liveFrames(turn);
        final events = _events(turn);
        expect(events, hasLength(frames.length), reason: turn);
        expect(events.first, isA<AssistantStreamStarted>(), reason: turn);
        expect(events[1], isA<AssistantStreamUserMessage>(), reason: turn);
        expect(events.last.isTerminal, isTrue, reason: turn);
      }
    });

    test('L4 + L6: the folded live turn equals the stored message — same '
        'text, same cards in the same order — so the swap moves nothing', () {
      // Before message_end only complete words are drawn; the flush that
      // carries message_end draws the rest, so compare the completed fold.
      for (final turn in [
        'sse_text_actions_en.json',
        'sse_products_en.json',
        'sse_delivery_info_empty_en.json',
        'sse_recipe_offers_en.json',
      ]) {
        final events = _events(turn);
        final live = _fold(events);
        final stored = (events.last as AssistantStreamCompleted).message;
        expect(live.richText, stored.richText, reason: turn);
        expect(live.cards, stored.cards, reason: turn);
        final streaming = _fold(events.sublist(0, events.length - 1));
        expect(streaming.cards, stored.cards, reason: turn);
        expect(stored.isAssistant, isTrue);
      }
    });

    test('L5: chips arrive only with message_end', () {
      final events = _events('sse_products_en.json');
      final live = _fold(events.sublist(0, events.length - 1));
      final stored = (events.last as AssistantStreamCompleted).message;
      expect(live.cards.whereType<AssistantActionsBlock>(), isEmpty);
      expect(stored.suggestions, isNotEmpty);
      // N8: one products block per search_products call — drawn as ONE rail.
      expect(stored.blocks.whereType<AssistantProductsBlock>(), hasLength(2));
      final rail = stored.cards.whereType<AssistantProductsBlock>().single;
      expect(rail.products, hasLength(2));
    });

    test('L7: the cart turn ends in INTERNAL_ERROR; the proposal stays', () {
      for (final turn in [
        'sse_cart_action_persist_error_en.json',
        'sse_cart_action_persist_error_ar.json',
      ]) {
        final folded = _fold(_events(turn));
        expect(folded.isFailed, isTrue, reason: turn);
        expect(folded.errorCode, 'INTERNAL_ERROR');
        expect(folded.displayErrorMessage, isNull, reason: 'N4');
        expect(
          folded.cards.whereType<AssistantCartActionBlock>(),
          hasLength(1),
        );
        expect(folded.text, isNotEmpty);
      }
    });

    test('L13: the empty delivery_info never becomes a card', () {
      final events = _events('sse_delivery_info_empty_en.json');
      final stored = (events.last as AssistantStreamCompleted).message;
      expect(
        stored.blocks.whereType<AssistantDeliveryInfoBlock>(),
        hasLength(1),
      );
      expect(stored.cards.whereType<AssistantDeliveryInfoBlock>(), isEmpty);
    });

    test(
      'L14: the streamed user message has no blocks and renders content',
      () {
        final user =
            (_events('sse_text_actions_en.json')[1]
                    as AssistantStreamUserMessage)
                .message;
        expect(user.isUser, isTrue);
        expect(user.blocks, isEmpty);
        expect(user.richText.plainText, user.content);
      },
    );

    test('an unknown event name is skipped; a broken known one throws', () {
      expect(
        AssistantStreamEventModel.fromFrame(
          const ServerSentEvent(event: 'ping', data: 'x'),
        ),
        isNull,
      );
      expect(
        () => AssistantStreamEventModel.fromFrame(
          const ServerSentEvent(event: 'message_end', data: '{}'),
        ),
        throwsA(isA<ParsingException>()),
      );
      expect(
        () => AssistantStreamEventModel.fromFrame(
          const ServerSentEvent(event: 'text_delta', data: 'not json'),
        ),
        throwsA(isA<ParsingException>()),
      );
    });

    test('a numeric error code is read as text', () {
      final model = AssistantStreamEventModel.fromFrame(
        const ServerSentEvent(event: 'error', data: '{"code":503}'),
      );
      expect((model!.toEntity() as AssistantStreamFailed).code, '503');
    });
  });

  group('conversations', () {
    test('detail → thread in server order; user text blocks not drawn', () {
      final thread = AssistantConversationDetailModel.fromJson(
        AssistantFixtures.liveResults('conversation_detail_en.json'),
      ).toEntity();
      expect(thread.conversationId, '6ab511ac9e3ba2a7a933b077');
      expect(thread.conversation?.status, AssistantConversationStatus.active);
      expect(thread.entries, hasLength(4));
      final messages = [
        for (final entry in thread.entries)
          (entry as AssistantMessageEntry).message,
      ];
      expect(messages.map((m) => m.role), [
        AssistantRole.user,
        AssistantRole.assistant,
        AssistantRole.user,
        AssistantRole.assistant,
      ]);
      expect(
        messages.every((m) => m.feedback == AssistantFeedback.none),
        isTrue,
      );
      // The first reply: text + empty delivery_info (hidden) + chips.
      expect(messages[1].cards, isEmpty);
      expect(messages[1].suggestions, isNotEmpty);
      // Chips are live only on the last row — which has none (N11).
      expect(thread.suggestionsKey, isNull);
      expect(messages[3].cards.map((c) => c.runtimeType), [
        AssistantRecipeBlock,
        AssistantOffersBlock,
      ]);
    });

    test('list → feed; AR title kept; pagination read', () {
      final feed = AssistantConversationsPageModel.fromJson(
        AssistantFixtures.liveResults('conversations_list_en.json'),
      ).toEntity();
      expect(feed.items, hasLength(3));
      expect(feed.hasMore, isFalse);
      expect(feed.total, 3);
      expect(feed.items[1].language, 'ar');
      expect(feed.resumable?.id, '6ab511ac9e3ba2a7a933b077');
    });

    test('a list without data[] is a ParsingException', () {
      expect(
        () => AssistantConversationsPageModel.fromJson(const {}),
        throwsA(isA<ParsingException>()),
      );
    });

    test('unknown conversation status → other; handed_off read', () {
      expect(
        AssistantConversationMapper.statusOf('handed_off'),
        AssistantConversationStatus.handedOff,
      );
      expect(
        AssistantConversationMapper.statusOf('archived'),
        AssistantConversationStatus.other,
      );
    });
  });

  group('replies', () {
    test('confirm result: blocks mapped, message kept', () {
      final result = AssistantActionResultModel.fromJson({
        'message': 'Added to your cart',
        'blocks': [
          {
            'kind': 'cart_action',
            'actionId': 'a059e104bf1e645249a95219',
            'status': 'confirmed',
            'items': <Object?>[],
          },
          {
            'kind': 'cart_summary',
            'cart': {
              'itemCount': 2,
              'totals': {'total': 4500},
            },
          },
        ],
      }).toEntity();
      expect(result.message, 'Added to your cart');
      expect(
        (result.blocks.first as AssistantCartActionBlock).status,
        AssistantActionStatus.confirmed,
      );
      // `meetsMinOrder` absent → true, like the cart DTO.
      expect(
        (result.blocks.last as AssistantCartSummaryBlock).cart.meetsMinOrder,
        isTrue,
      );
    });

    test('handoff ticket needs its id', () {
      expect(
        () => AssistantHandoffTicketModel.fromJson(const {'ticketNumber': 'T'}),
        throwsA(isA<ParsingException>()),
      );
    });

    test('availability from /v1/init: both switches; a missing flag does not '
        'veto; a missing block means off', () {
      AssistantAvailabilityModel parse(Map<String, dynamic> store) =>
          AssistantAvailabilityModel.fromInitJson({'store': store});
      final on = parse({
        'assistant': {'enabled': true, 'allowGuests': true},
        'featureFlags': {'assistant': true},
      }).toEntity();
      expect(on.isAvailable, isTrue);
      expect(on.allowGuests, isTrue);
      expect(
        parse({
          'assistant': {'enabled': true, 'allowGuests': false},
          'featureFlags': <String, dynamic>{},
        }).toEntity().isAvailable,
        isTrue,
      );
      expect(
        parse({
          'assistant': {'enabled': true},
          'featureFlags': {'assistant': false},
        }).toEntity().isAvailable,
        isFalse,
      );
      expect(parse(const {}).toEntity().isAvailable, isFalse);
    });

    test('feedback wire values', () {
      expect(AssistantMessageMapper.feedbackWire(AssistantFeedback.up), 'up');
      expect(
        AssistantMessageMapper.feedbackWire(AssistantFeedback.none),
        isNull,
      );
      expect(AssistantMessageMapper.feedbackOf('down'), AssistantFeedback.down);
      expect(AssistantMessageMapper.feedbackOf('meh'), AssistantFeedback.none);
    });
  });
}
