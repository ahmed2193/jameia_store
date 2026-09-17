import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/network/api_headers.dart';
import 'package:jameia_mart/src/core/network/event_stream_client.dart';

import 'network_test_fakes.dart';

void main() {
  Stream<List<int>> bytes(String text) => Stream.value(utf8.encode(text));

  group('parse', () {
    test(
      'splits frames on blank lines, joins multi-line data, reads event/id',
      () async {
        const raw =
            'event: notification\n'
            'id: 7\n'
            'data: {"a":\n'
            'data:  1}\n'
            '\n'
            ': heartbeat\n'
            'data: plain\n'
            '\n'
            'data: tail-without-blank-line';
        final events = await DioEventStreamClient.parse(bytes(raw)).toList();

        expect(events, [
          const ServerSentEvent(
            event: 'notification',
            data: '{"a":\n 1}',
            id: '7',
          ),
          const ServerSentEvent(data: 'plain', id: '7'),
          const ServerSentEvent(data: 'tail-without-blank-line', id: '7'),
        ]);
        expect(events.first.json, {'a': 1});
        expect(events[1].json, isNull);
      },
    );

    test('accepts CRLF line endings and chunked bytes', () async {
      final chunks = Stream.fromIterable([
        utf8.encode('event: n\r\ndata: {"x"'),
        utf8.encode(':2}\r\n\r\n'),
      ]);
      final events = await DioEventStreamClient.parse(chunks).toList();
      expect(events.single, const ServerSentEvent(event: 'n', data: '{"x":2}'));
    });
  });

  group('connect', () {
    late FakeHttpClientAdapter adapter;
    late List<Duration> waits;

    DioEventStreamClient build(FakeHttpClientAdapter transport) {
      adapter = transport;
      waits = [];
      final dio = Dio()..httpClientAdapter = adapter;
      return DioEventStreamClient(dio, wait: (delay) async => waits.add(delay));
    }

    ResponseBody frames(String text) => ResponseBody(
      Stream.value(utf8.encode(text)),
      200,
      headers: {
        Headers.contentTypeHeader: [ApiHeaders.eventStreamMediaType],
      },
    );

    test(
      'requests text/event-stream with no receive timeout and emits events',
      () async {
        final client = build(
          FakeHttpClientAdapter(
            (_, call) => call == 0
                ? frames('event: notification\ndata: {"id":1}\n\n')
                : frames(''),
          ),
        );

        final first = await client.connect('/v1/notifications/sse').first;

        expect(first.event, 'notification');
        expect(first.json, {'id': 1});
        final request = adapter.requests.first;
        expect(request.responseType, ResponseType.stream);
        expect(request.receiveTimeout, Duration.zero);
        expect(
          request.headers[ApiHeaders.accept],
          ApiHeaders.eventStreamMediaType,
        );
      },
    );

    test('reconnects with backoff when the stream ends', () async {
      final client = build(
        FakeHttpClientAdapter(
          (_, call) => switch (call) {
            0 => frames('data: one\n\n'),
            1 => frames(''), // server closed without events
            _ => frames('data: two\n\n'),
          },
        ),
      );

      final events = await client
          .connect('/v1/notifications/sse')
          .take(2)
          .toList();

      expect(events.map((e) => e.data), ['one', 'two']);
      expect(waits, [const Duration(seconds: 1), const Duration(seconds: 2)]);
    });

    test('connections that deliver data but die at once still escalate the '
        'backoff (a proxy that accepts then hangs up must not be hammered)', () async {
      final client = build(
        FakeHttpClientAdapter((_, call) => frames('data: frame-$call\n\n')),
      );

      final events = await client
          .connect('/v1/notifications/sse')
          .take(4)
          .toList();

      expect(events.map((e) => e.data), [
        'frame-0',
        'frame-1',
        'frame-2',
        'frame-3',
      ]);
      // Receiving bytes never resets the schedule: 1s, 2s, 4s — not 1s, 1s, 1s.
      expect(waits, const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
      ]);
    });

    test(
      'a connection that stayed up long enough resets the backoff',
      () async {
        // The client reads the clock twice per connection: when it connects
        // and when it drops. Scripted so connection #2 "lived" two minutes
        // (Dio consumes the fake body eagerly, so real time cannot be used).
        const lifetimes = [
          Duration.zero,
          Duration.zero,
          Duration(minutes: 2),
          Duration.zero,
        ];
        var clock = DateTime.utc(2026, 9, 17, 12);
        var reads = 0;
        DateTime now() {
          if (reads.isOdd) clock = clock.add(lifetimes[reads ~/ 2]);
          reads++;
          return clock;
        }

        adapter = FakeHttpClientAdapter(
          (_, call) => frames('data: frame-$call\n\n'),
        );
        waits = [];
        final client = DioEventStreamClient(
          Dio()..httpClientAdapter = adapter,
          wait: (delay) async => waits.add(delay),
          minHealthyConnection: const Duration(seconds: 30),
          now: now,
        );

        await client.connect('/v1/notifications/sse').take(4).toList();

        // Calls 0 and 1 died at once (1s, 2s); call 2 lived 2 min, so the
        // drop after it starts over at 1s instead of continuing with 4s.
        expect(waits, const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 1),
        ]);
      },
    );

    test(
      'ends with the typed exception when the server rejects (401)',
      () async {
        final client = build(
          FakeHttpClientAdapter(
            (_, _) => envelope(
              status: 401,
              statusMessage: 'AUTHENTICATION_REQUIRED',
              errorMessage: 'Sign in',
            ),
          ),
        );

        await expectLater(
          client.connect('/v1/notifications/sse'),
          emitsError(isA<UnauthorizedException>()),
        );
        expect(waits, isEmpty);
      },
    );

    test('retries a connection error instead of failing', () async {
      final client = build(
        FakeHttpClientAdapter(
          (options, call) => call == 0
              ? throw DioException.connectionError(
                  requestOptions: options,
                  reason: 'down',
                )
              : frames('data: back\n\n'),
        ),
      );

      final event = await client.connect('/v1/notifications/sse').first;

      expect(event.data, 'back');
      expect(waits, [const Duration(seconds: 1)]);
    });

    test('cancelling the subscription stops reconnecting', () async {
      final client = build(
        FakeHttpClientAdapter((_, _) => frames('data: a\n\n')),
      );

      final subscription = client
          .connect('/v1/notifications/sse')
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      final callsAtCancel = adapter.requests.length;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(adapter.requests.length, callsAtCancel);
    });

    test(
      'a silent connection is dropped and re-opened (idle watchdog)',
      () async {
        final silent = StreamController<List<int>>(); // never emits, never ends
        addTearDown(silent.close);
        adapter = FakeHttpClientAdapter(
          (_, call) => call == 0
              ? ResponseBody(silent.stream.cast(), 200)
              : frames('data: alive\n\n'),
        );
        waits = [];
        final dio = Dio()..httpClientAdapter = adapter;
        final client = DioEventStreamClient(
          dio,
          wait: (delay) async => waits.add(delay),
          idleTimeout: const Duration(milliseconds: 30),
        );

        final event = await client.connect('/v1/notifications/sse').first;

        expect(event.data, 'alive');
        expect(adapter.requests, hasLength(2));
        expect(waits, [const Duration(seconds: 1)]);
      },
    );

    test('heartbeat comments keep a quiet stream alive', () async {
      final body = StreamController<List<int>>();
      addTearDown(body.close);
      final client = DioEventStreamClient(
        Dio()
          ..httpClientAdapter = FakeHttpClientAdapter(
            (_, _) => ResponseBody(body.stream.cast(), 200),
          ),
        wait: (_) async {},
        idleTimeout: const Duration(milliseconds: 60),
      );
      final events = <String>[];
      final subscription = client
          .connect('/v1/notifications/sse')
          .listen((event) => events.add(event.data));

      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        body.add(utf8.encode(': ping\n\n'));
      }
      body.add(utf8.encode('data: still-here\n\n'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await subscription.cancel();

      expect(events, ['still-here']);
    });

    test(
      'a connection that breaks MID-stream reconnects (raw, non-Dio error)',
      () async {
        final client = build(
          FakeHttpClientAdapter(
            (_, call) => call == 0
                ? ResponseBody(
                    Stream<List<int>>.error(
                      const FormatException('connection reset by peer'),
                    ).cast(),
                    200,
                  )
                : frames('data: recovered\n\n'),
          ),
        );

        final event = await client.connect('/v1/notifications/sse').first;

        expect(event.data, 'recovered');
        expect(adapter.requests, hasLength(2));
        expect(waits, [const Duration(seconds: 1)]);
      },
    );

    test('a 5xx is an outage to ride out, not a rejection', () async {
      final client = build(
        FakeHttpClientAdapter(
          (_, call) => call == 0
              ? envelope(
                  status: 502,
                  statusMessage: 'SERVICE_UNAVAILABLE',
                  errorMessage: 'deploying',
                )
              : frames('data: back-after-deploy\n\n'),
        ),
      );

      final event = await client.connect('/v1/notifications/sse').first;

      expect(event.data, 'back-after-deploy');
      expect(waits, [const Duration(seconds: 1)]);
    });

    test('malformed UTF-8 does not take the stream down', () async {
      final events = await DioEventStreamClient.parse(
        Stream.fromIterable([
          [
            0x64,
            0x61,
            0x74,
            0x61,
            0x3a,
            0x20,
            0xff,
            0xfe,
            0x0a,
            0x0a,
          ], // data: <bad>
          utf8.encode('data: ok\n\n'),
        ]),
      ).toList();

      expect(events, hasLength(2));
      expect(events.last.data, 'ok');
    });

    test('backoff schedule caps at 30s', () {
      expect(
        DioEventStreamClient.reconnectDelayFor(0),
        const Duration(seconds: 1),
      );
      expect(
        DioEventStreamClient.reconnectDelayFor(3),
        const Duration(seconds: 8),
      );
      expect(
        DioEventStreamClient.reconnectDelayFor(10),
        const Duration(seconds: 30),
      );
      // `1 << attempt` overflows past ~44: the delay must stay at the cap,
      // never go negative / zero (that would be a hot reconnect loop).
      for (final attempt in [44, 58, 63, 64, 1000]) {
        expect(
          DioEventStreamClient.reconnectDelayFor(attempt),
          const Duration(seconds: 30),
          reason: 'attempt $attempt',
        );
      }
    });
  });
}
