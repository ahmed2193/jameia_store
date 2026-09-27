import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/network/dio_consumer.dart';
import 'package:hero_mart/src/core/network/end_points.dart';
import 'package:hero_mart/src/core/network/event_stream_client.dart';
import 'package:hero_mart/src/features/assistant/data/datasources/assistant_remote_data_source.dart';
import 'package:hero_mart/src/features/assistant/data/models/assistant_stream_event_model.dart';

import '../../../core/network/network_test_fakes.dart';
import '../../notifications/notifications_test_fakes.dart';
import '../assistant_fixtures.dart';

void main() {
  late FakeHttpClientAdapter adapter;
  late FakeEventStreamClient events;

  AssistantRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
    adapter = transport;
    events = FakeEventStreamClient();
    return AssistantRemoteDataSourceImpl(
      DioConsumer(Dio()..httpClientAdapter = adapter),
      events,
    );
  }

  tearDown(() => events.controller.close());

  Map<String, dynamic> initResults({bool enabled = true}) => {
    'store': {
      'assistant': {'enabled': enabled, 'allowGuests': true},
      'featureFlags': {'assistant': true},
    },
  };

  group('availability', () {
    test('GETs /v1/init once per run (memoized)', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody(initResults())),
      );
      final first = await dataSource.getAvailability();
      final second = await dataSource.getAvailability();
      expect(first.enabled, isTrue);
      expect(identical(first, second), isTrue);
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.path, EndPoints.init);
    });

    test('a failed read is not memoized', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (options, call) => call == 0
              ? throw DioException.connectionError(
                  requestOptions: options,
                  reason: 'offline',
                )
              : okBody(initResults()),
        ),
      );
      await expectLater(
        dataSource.getAvailability(),
        throwsA(isA<NoInternetConnectionException>()),
      );
      expect((await dataSource.getAvailability()).enabled, isTrue);
      expect(adapter.requests, hasLength(2));
    });
  });

  test('conversations: GET with page + limit, parsed', () async {
    final dataSource = build(
      FakeHttpClientAdapter(
        (_, _) =>
            okBody(AssistantFixtures.liveResults('conversations_list_en.json')),
      ),
    );
    final page = (await dataSource.getConversations(page: 2, limit: 20)).model;
    final request = adapter.requests.single;
    expect(request.method, 'GET');
    expect(request.path, EndPoints.assistantConversations);
    expect(request.queryParameters, {'page': 2, 'limit': 20});
    expect(page.items, hasLength(3));
  });

  test('conversation detail: GET by id; 404 → NotFoundException', () async {
    final dataSource = build(
      FakeHttpClientAdapter(
        (options, _) => options.path.endsWith('missing')
            ? envelope(
                status: 404,
                statusMessage: 'RESOURCE_NOT_FOUND',
                errorMessage: 'Conversation not found',
              )
            : okBody(
                AssistantFixtures.liveResults('conversation_detail_en.json'),
              ),
      ),
    );
    final detail = await dataSource.getConversation('6ab511ac9e3ba2a7a933b077');
    expect(
      adapter.requests.single.path,
      EndPoints.assistantConversation('6ab511ac9e3ba2a7a933b077'),
    );
    expect(detail.messages, hasLength(4));
    await expectLater(
      dataSource.getConversation('missing'),
      throwsA(
        isA<NotFoundException>().having(
          (e) => e.code,
          'code',
          'RESOURCE_NOT_FOUND',
        ),
      ),
    );
  });

  group('sendMessage', () {
    test('sends { message, conversationId } to the stream client and parses '
        'every live frame', () async {
      final dataSource = build(FakeHttpClientAdapter((_, _) => okBody(null)));
      events.onSend = (_, _) => Stream.fromIterable(
        AssistantFixtures.liveFrames('sse_products_en.json'),
      );

      final parsed = await dataSource
          .sendMessage(message: 'milk', conversationId: 'c1')
          .toList();

      expect(events.sends.single.path, EndPoints.assistantMessages);
      expect(events.sends.single.data, {
        'message': 'milk',
        'conversationId': 'c1',
      });
      expect(parsed.first, isA<AssistantStreamStartedModel>());
      expect(parsed.last, isA<AssistantStreamCompletedModel>());
      expect(adapter.requests, isEmpty, reason: 'no envelope request');
    });

    test('a new chat sends no conversationId', () async {
      final dataSource = build(FakeHttpClientAdapter((_, _) => okBody(null)));
      await dataSource.sendMessage(message: 'hi').toList();
      expect(events.sends.single.data, {'message': 'hi'});
    });

    test('broken and unknown frames are skipped; the turn goes on', () async {
      final dataSource = build(FakeHttpClientAdapter((_, _) => okBody(null)));
      events.onSend = (_, _) => Stream.fromIterable(const [
        ServerSentEvent(event: 'message_start', data: '{"conversationId":"c"}'),
        ServerSentEvent(event: 'ping', data: '{}'),
        ServerSentEvent(event: 'block', data: '{"block":{"kind":"future"}}'),
        ServerSentEvent(event: 'text_delta', data: 'not json'),
        ServerSentEvent(event: 'text_delta', data: '{"delta":" hi"}'),
      ]);

      final parsed = await dataSource.sendMessage(message: 'x').toList();

      expect(parsed, hasLength(2));
      expect((parsed.last as AssistantStreamTextDeltaModel).delta, ' hi');
    });

    test('a transport error passes through (the repository maps it)', () async {
      final dataSource = build(FakeHttpClientAdapter((_, _) => okBody(null)));
      events.onSend = (_, _) => Stream.error(
        const BadRequestException('bad', code: 'VALIDATION_ERROR'),
      );
      await expectLater(
        dataSource.sendMessage(message: 'x'),
        emitsError(isA<BadRequestException>()),
      );
    });
  });

  test('confirm POSTs {} to the action route', () async {
    final dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => okBody({
          'message': 'Added',
          'blocks': [
            {
              'kind': 'cart_action',
              'actionId': 'act-12345',
              'status': 'confirmed',
              'items': <Object?>[],
            },
          ],
        }),
      ),
    );
    final result = await dataSource.confirmAction('act-12345');
    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, EndPoints.assistantActionConfirm('act-12345'));
    expect(request.data, <String, dynamic>{});
    expect(result.message, 'Added');
    expect(result.blocks, hasLength(1));
  });

  test('confirm 404 (L7) → NotFoundException "Action not found"', () async {
    final saved = AssistantFixtures.liveEnvelope(
      'confirm_404_action_not_found.json',
    );
    final dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => envelope(
          status: 404,
          statusMessage: saved['statusMessage'] as String,
          errorMessage: (saved['error'] as Map)['message'] as String,
        ),
      ),
    );
    await expectLater(
      dataSource.confirmAction('a059e104bf1e645249a95219'),
      throwsA(
        isA<NotFoundException>().having(
          (e) => e.message,
          'message',
          'Action not found',
        ),
      ),
    );
  });

  test('handoff POSTs an EMPTY object — no guessed category', () async {
    final dataSource = build(
      FakeHttpClientAdapter(
        (_, _) => okBody({
          'ticketId': '6ab0000000000000000000t1',
          'ticketNumber': 'T-42',
          'message': 'A person will reply soon',
        }),
      ),
    );
    final ticket = await dataSource.requestHandoff('c1');
    expect(adapter.requests.single.path, EndPoints.assistantHandoff('c1'));
    expect(adapter.requests.single.data, <String, dynamic>{});
    expect(ticket.ticketNumber, 'T-42');
  });

  test('feedback POSTs up / down / null', () async {
    final dataSource = build(
      FakeHttpClientAdapter((_, _) => okBody({'message': 'Thanks'})),
    );
    await dataSource.rateMessage(messageId: 'm1', feedback: 'up');
    await dataSource.rateMessage(messageId: 'm1');
    expect(
      adapter.requests.first.path,
      EndPoints.assistantMessageFeedback('m1'),
    );
    expect(adapter.requests.first.data, {'feedback': 'up'});
    expect(adapter.requests.last.data, {'feedback': null});
  });

  test('a non-object payload is a ParsingException', () async {
    final dataSource = build(FakeHttpClientAdapter((_, _) => okBody(['x'])));
    await expectLater(
      dataSource.getConversations(page: 1, limit: 20),
      throwsA(isA<ParsingException>()),
    );
  });

  test('the stream really is one POST through the real client', () async {
    // End-to-end on the real `DioEventStreamClient`: the saved live wire
    // bytes (comment included, several frames per chunk) parse into the
    // same events.
    events = FakeEventStreamClient(); // closed by tearDown
    final transport = FakeHttpClientAdapter(
      (_, _) => ResponseBody.fromString(
        AssistantFixtures.liveWire('sse_text_actions_en.json'),
        200,
      ),
    );
    final dataSource = AssistantRemoteDataSourceImpl(
      DioConsumer(Dio()..httpClientAdapter = transport),
      DioEventStreamClient(Dio()..httpClientAdapter = transport),
    );
    final parsed = await dataSource.sendMessage(message: 'hi').toList();
    expect(transport.requests.single.method, 'POST');
    expect(parsed.first, isA<AssistantStreamStartedModel>());
    expect(parsed.last, isA<AssistantStreamCompletedModel>());
    expect(
      parsed.whereType<AssistantStreamTextDeltaModel>().length,
      greaterThan(10),
    );
  });
}
