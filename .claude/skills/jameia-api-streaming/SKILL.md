---
name: jameia-api-streaming
description: Consume a jm3eia text/event-stream (SSE) route in JameiaMart through EventStreamClient — live notifications (GET /v1/notifications/sse), assistant message streams, any server-push feed. Use when a route streams instead of returning the JSON envelope, when adding a live / real-time feature, or when debugging reconnects, duplicate connections or a stream that silently stops.
---

# Server-sent events — `EventStreamClient`

`ApiConsumer` cannot read a stream (it unwraps a JSON envelope). Streaming routes go through
`core/network/event_stream_client.dart`. Shipped example to mirror end to end:
`features/notifications/` (`watchLive`).

## What the client already guarantees

`DioEventStreamClient.connect(path, {queryParameters})` → `Stream<ServerSentEvent>`
(`event`, `data`, `id`, `json` = `data` decoded as a JSON object or `null`).

- Runs on the **shared Dio**: Bearer, refresh, `Accept-Language`, debug trace all apply.
  `Accept: text/event-stream`, `ResponseType.stream`, no receive timeout.
- WHATWG parsing: multi-line `data:`, `event:`, `id:`, `:` heartbeat comments ignored,
  malformed UTF-8 → U+FFFD (one bad frame never kills the connection).
- **Reconnects by itself** with 1 s → 2 s → 4 s … 30 s backoff (exponent clamped) on: transport
  error, mid-stream break (raw `HttpException: Connection closed while receiving data` /
  `SocketException` — what a proxy idle-timeout or a network switch looks like), 5xx, clean
  server close, and **90 s of total silence** (idle watchdog; heartbeats count as life — a
  half-open socket never errors by itself).
- **The backoff starts over only after a connection STAYED up ≥ 30 s**
  (`defaultMinHealthyConnection`). Receiving bytes is not enough: a server / proxy that accepts
  the stream, sends a frame and hangs up would otherwise be re-called every second, burning
  the customer's rate-limit budget (300 req / min on the live host).
- One log line per drop under `sse`:
  `dropped /v1/notifications/sse after 60s (HttpException: Connection closed …) → reconnecting in 1s`.
  The lifetime tells you who cut it: a constant ~60 s = nginx `proxy_read_timeout` with no
  server heartbeat — a **backend** fix (heartbeat comment every ≤ 25 s; `proxy_buffering off`
  and a long `proxy_read_timeout` on the route), not something the app can prevent.
- **Ends with an error only** on 401 (after the automatic refresh), 403, 404.
- **The notifications stream is opt-in**: `AppEnv.liveNotifications`
  (`--dart-define=LIVE_NOTIFICATIONS=true`). By default `notifications_injection_container.dart`
  hands both cubits a `null` live source, so no `GET …/sse` is made (the production proxy
  drops the idle stream every ~60 s and sends no heartbeat). Build with the flag to test the
  live path (the mock API heartbeats every 15 s).
- Connects on first listen; cancelling the subscription cancels the HTTP request.

Do not add your own retry loop, timer, or `Dio` call around it.

## Build order for a streaming feature

1. `EndPoints`: the path constant **and** its entry in `EndPoints.streamingPaths`.
2. **Datasource** — depends on `EventStreamClient` (+ `ApiConsumer` for the normal routes):
   - filter by event name (`frame.event == 'notification'`);
   - parse with `.expand(_parseFrame)` returning zero or one DTO — a bad payload is
     `log`ged and **dropped**, the stream survives;
   - **one connection per device**: expose a broadcast `StreamController` over a single
     upstream subscription (`_live ??= _openShared()`), open on first listener, close + forget
     itself when the last one leaves or the server ends it. Two cubits listening must never
     mean two HTTP connections.
   - broadcast `onCancel` cannot return a future: `unawaited(upstream?.cancel())`.
3. **Repository** — `Stream<Entity> watchX() => guardStream(_remote.watchX().map((m) => m.toEntity()));`
   `guardStream` (in `BaseRepositoryMixin`) re-emits every stream error as its `Failure`, so a
   listener sees `UnauthorizedFailure`, never an exception type. Contract returns `Stream<T>`
   (no `Either` — errors travel as stream errors).
4. **Use case** — `implements StreamUseCase<Entity, NoParams>`.
5. **Cubit** — owns the `StreamSubscription`:
   ```dart
   void _listenLive() {
     if (_live != null) return;                      // never subscribe twice
     _live = _watchLive(const NoParams()).listen(
       (item) => safeEmit(state.copyWith(feed: state.feed.prepend(item))),
       onError: (Object error) { log('live stream ended', name: _logName, error: error); _live = null; },
       onDone: () => _live = null,
     );
   }

   @override
   Future<void> close() async {
     await _live?.cancel();
     _live = null;
     return super.close();
   }
   ```
   Subscribe **after** the first successful load, so a pushed item never lands in an empty
   list that a page-1 reply then overwrites. A stream error is not a screen error: the
   feature keeps working without live updates.
6. **Lifecycle** — a stream that must live as long as the session (badge counters) is started /
   stopped from `app.dart`'s listener on `AuthSessionCubit` (`UnreadNotificationsCubit.start()/stop()`),
   not from a page. Page-scoped streams die with the page's cubit.
7. **De-dupe** — the same item can arrive over SSE and in the next page fetch: the feed
   entity's `prepend` / `merge` de-dupe by id.

## Limits you must know

- `connect` is **GET only**. `POST /v1/assistant/messages` (streamed reply to a body) needs
  the client extended in core (method + body parameters, and *no* auto-reconnect for a
  one-shot reply — replaying a `POST` would send the message twice). Do that in
  `core/network/event_stream_client.dart` with tests; do not open a stream from a feature.
- No `Last-Event-ID` resume: after a reconnect, missed events are recovered by re-fetching
  the list (pull-to-refresh / next `load`), not by the stream.
- The debug trace prints `body: <stream>` for these calls (one `api` block per (re)connect).
  `sse` logs the connection lifecycle only (`connected`, `dropped … → reconnecting`, `rejected`);
  a dropped malformed frame / list row is logged under the datasource's / model's own name
  (`NotificationsRemoteDataSource`, `NotificationsPageModel`).

## Tests

`FakeEventStreamClient` (`test/features/notifications/notifications_test_fakes.dart`) scripts
frames and errors. Cover: event-name filter, malformed frame dropped, ONE upstream for two
listeners, upstream cancelled when the last listener leaves, error → `Failure` in the
repository, cubit cancels on `close()`. Client-level behavior is pinned by
`test/core/network/event_stream_client_test.dart`: parser, backoff schedule + escalation for
short-lived connections + reset after a healthy one, idle watchdog, heartbeats, mid-stream
break, 5xx rides out, 401 ends the stream (403 / 404 share that code path but have no test
of their own yet — add one if you touch it).
