import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

import '../error/exceptions.dart';
import 'api_exception_mapper.dart';
import 'api_headers.dart';

/// One `text/event-stream` frame.
///
/// ```
/// event: notification
/// data: {"_id": "…", "type": "order.delivered", …}
/// ```
class ServerSentEvent extends Equatable {
  const ServerSentEvent({
    this.event = defaultEvent,
    required this.data,
    this.id,
  });

  /// Frames without an `event:` line are `message` per the SSE spec.
  static const String defaultEvent = 'message';

  final String event;

  /// Joined `data:` lines (multi-line payloads are newline-separated).
  final String data;
  final String? id;

  /// [data] decoded as a JSON object, or `null` when it is not one.
  Map<String, dynamic>? get json {
    try {
      final decoded = jsonDecode(data);
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    } on FormatException {
      return null;
    }
  }

  @override
  List<Object?> get props => [event, data, id];
}

/// The dedicated client for the two streaming routes (`EndPoints.streamingPaths`)
/// that bypass the JSON envelope. Feature datasources depend on THIS, never on
/// Dio, exactly like `ApiConsumer` for request/response calls.
abstract class EventStreamClient {
  /// Opens the stream and keeps it open: a dropped connection reconnects with
  /// exponential backoff until the subscription is cancelled — whether the
  /// drop is a transport error, a mid-stream break, a 5xx or plain silence.
  /// The stream ends with an `AppException` only when the server definitively
  /// rejects the connection (401 after the automatic refresh, 403, 404).
  Stream<ServerSentEvent> connect(
    String path, {
    Map<String, dynamic>? queryParameters,
  });
}

/// SSE over the shared [Dio] (so `AuthInterceptor`, `AppHeadersInterceptor`
/// and the debug trace all apply) with `ResponseType.stream` and no Dio
/// receive timeout. Liveness is a watchdog instead: when NOTHING arrives —
/// not even a heartbeat comment — for [idleTimeout], the connection is treated
/// as dead (a half-open socket never errors on its own: NAT, proxy, a server
/// killed without FIN) and re-opened.
class DioEventStreamClient implements EventStreamClient {
  DioEventStreamClient(
    this._dio, {
    this._wait = _sleep,
    this._idleTimeout = defaultIdleTimeout,
    this._minHealthyConnection = defaultMinHealthyConnection,
    this._now = DateTime.now,
  });

  /// Longest silence tolerated before reconnecting. Servers heartbeat far more
  /// often (15–30 s), so a healthy stream never trips it.
  static const Duration defaultIdleTimeout = Duration(seconds: 90);

  /// Reconnect schedule: 1s, 2s, 4s … capped at [maxReconnectDelay].
  static const Duration baseReconnectDelay = Duration(seconds: 1);
  static const Duration maxReconnectDelay = Duration(seconds: 30);

  /// A connection must stay open this long before its drop counts as "the link
  /// was fine" and the backoff starts over. Receiving bytes is NOT enough: a
  /// server or proxy that accepts the stream, sends a first frame and hangs up
  /// would otherwise pin the delay at [baseReconnectDelay] forever — a
  /// reconnect per second that burns the customer's rate-limit budget.
  static const Duration defaultMinHealthyConnection = Duration(seconds: 30);

  static const String _logName = 'sse';
  static const String _eventField = 'event';
  static const String _dataField = 'data';
  static const String _idField = 'id';
  static const String _commentPrefix = ':';

  final Dio _dio;
  final Future<void> Function(Duration delay) _wait;
  final Duration _idleTimeout;
  final Duration _minHealthyConnection;
  final DateTime Function() _now;

  @override
  Stream<ServerSentEvent> connect(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    late final StreamController<ServerSentEvent> controller;
    var cancelled = false;
    CancelToken? cancelToken;

    Future<void> run() async {
      var attempt = 0;
      while (!cancelled) {
        cancelToken = CancelToken();
        DateTime? connectedAt;
        // Why this connection ended — one line for the log below.
        String reason;
        try {
          final response = await _dio.get<ResponseBody>(
            path,
            queryParameters: queryParameters,
            cancelToken: cancelToken,
            options: Options(
              responseType: ResponseType.stream,
              receiveTimeout: Duration.zero,
              headers: {ApiHeaders.accept: ApiHeaders.eventStreamMediaType},
            ),
          );
          connectedAt = _now();
          log('connected $path', name: _logName);
          var idledOut = false;
          // Watch the RAW bytes so heartbeat comments count as life.
          final bytes = response.data!.stream.timeout(
            _idleTimeout,
            onTimeout: (sink) {
              idledOut = true;
              sink.close();
            },
          );
          await for (final event in parse(bytes)) {
            if (cancelled) return;
            controller.add(event);
          }
          if (idledOut) {
            reason = 'silent for ${_idleTimeout.inSeconds}s';
            cancelToken?.cancel('idle');
          } else {
            reason = 'closed by the server';
          }
        } on DioException catch (exception) {
          if (cancelled || exception.type == DioExceptionType.cancel) return;
          final mapped = ApiExceptionMapper.fromDio(exception);
          // Only a definitive "you may not have this stream" ends it. A 5xx
          // during a deploy, a timeout or a transport error is an outage to
          // ride out with the backoff.
          if (mapped is ServerException &&
              _terminalStatuses.contains(mapped.statusCode)) {
            log('rejected $path: $mapped', name: _logName);
            controller.addError(mapped);
            await controller.close();
            return;
          }
          reason = '$mapped';
        } on Exception catch (error) {
          // A connection that breaks MID-stream surfaces raw (`HttpException:
          // Connection closed while receiving data`, `SocketException`) because
          // Dio only wraps the request phase. It is an ordinary drop — a proxy
          // idle timeout, a network switch — so it reconnects like any other
          // and is reported in one line: a stack trace per drop would bury the
          // console for an event that is expected on mobile.
          if (cancelled) return;
          reason = _firstLine(error);
        } on Object catch (error, stackTrace) {
          // An `Error` here is a bug (bad cast, state error), not a transport
          // drop: keep the trace, but still reconnect — letting it escape would
          // kill this loop silently and leave listeners waiting forever.
          if (cancelled) return;
          log(
            'stream failed $path',
            name: _logName,
            error: error,
            stackTrace: stackTrace,
          );
          reason = _firstLine(error);
        }
        if (cancelled) return;

        // Only a connection that STAYED up proves the link healthy and earns
        // a fresh backoff; short-lived ones keep escalating (1s, 2s, 4s … 30s).
        final lifetime = connectedAt == null
            ? null
            : _now().difference(connectedAt);
        if (lifetime != null && lifetime >= _minHealthyConnection) attempt = 0;
        final delay = reconnectDelayFor(attempt++);
        log(
          'dropped $path'
          '${lifetime == null ? '' : ' after ${lifetime.inSeconds}s'}'
          ' ($reason) → reconnecting in ${delay.inSeconds}s',
          name: _logName,
        );
        await _wait(delay);
      }
    }

    controller = StreamController<ServerSentEvent>(
      onListen: () => unawaited(run()),
      onCancel: () {
        cancelled = true;
        cancelToken?.cancel('stream cancelled');
      },
    );
    return controller.stream;
  }

  /// `baseReconnectDelay * 2^attempt`, capped at [maxReconnectDelay]. The
  /// exponent is clamped BEFORE shifting: `1 << attempt` overflows to a
  /// negative / zero factor past ~44 attempts, which would turn a long outage
  /// into a zero-delay reconnect loop.
  static Duration reconnectDelayFor(int attempt) {
    if (attempt >= _maxBackoffShift) return maxReconnectDelay;
    final delay = baseReconnectDelay * (1 << attempt);
    return delay > maxReconnectDelay ? maxReconnectDelay : delay;
  }

  /// `1s << 5 = 32s` already exceeds the 30 s cap.
  static const int _maxBackoffShift = 5;

  /// Statuses that mean "this client may not have the stream": signed out
  /// (after the automatic refresh), forbidden, or no such route.
  static const Set<int> _terminalStatuses = {401, 403, 404};

  /// Parses raw bytes into frames per the WHATWG SSE format: `event:`,
  /// `data:` (multi-line, joined with `\n`), `id:`; a blank line dispatches;
  /// `:` comment lines (heartbeats) and unknown fields are ignored.
  static Stream<ServerSentEvent> parse(Stream<List<int>> bytes) async* {
    var event = ServerSentEvent.defaultEvent;
    final data = <String>[];
    String? id;

    // `bind` (not `transform`): Dio hands over a `Stream<Uint8List>`, whose
    // runtime type does not satisfy `StreamTransformer<List<int>, String>`.
    // Malformed bytes decode to U+FFFD instead of throwing: one bad frame
    // must not take the connection down.
    final lines = const LineSplitter().bind(
      const Utf8Decoder(allowMalformed: true).bind(bytes),
    );
    await for (final line in lines) {
      if (line.isEmpty) {
        if (data.isNotEmpty) {
          yield ServerSentEvent(event: event, data: data.join('\n'), id: id);
        }
        event = ServerSentEvent.defaultEvent;
        data.clear();
        continue;
      }
      if (line.startsWith(_commentPrefix)) continue;

      final separator = line.indexOf(':');
      final field = separator < 0 ? line : line.substring(0, separator);
      var value = separator < 0 ? '' : line.substring(separator + 1);
      if (value.startsWith(' ')) value = value.substring(1);

      switch (field) {
        case _eventField:
          event = value;
        case _dataField:
          data.add(value);
        case _idField:
          id = value;
      }
    }
    if (data.isNotEmpty) {
      yield ServerSentEvent(event: event, data: data.join('\n'), id: id);
    }
  }

  static Future<void> _sleep(Duration delay) => Future<void>.delayed(delay);

  /// `HttpException: Connection closed while receiving data, uri = …` → the
  /// part before the first line break, so a drop stays a one-line log entry.
  static String _firstLine(Object error) => '$error'.split('\n').first.trim();
}
