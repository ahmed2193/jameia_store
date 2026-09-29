// Assistant history offline: the first page is kept on the device for the
// signed-in customer — never for a guest, whose chats move to the customer
// at sign-in — and later pages never are; the history paints the saved copy
// marked stale (no skeleton), asks again once on reconnect, and a next page
// that failed waits for the connection.
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/data/datasources/cache_slots.dart';
import 'package:hero_mart/src/core/domain/entities/screen_load.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/network/dio_consumer.dart';
import 'package:hero_mart/src/core/network/event_stream_client.dart';
import 'package:hero_mart/src/core/storage/cache_owner.dart';
import 'package:hero_mart/src/features/assistant/data/datasources/assistant_history_cache_data_source.dart';
import 'package:hero_mart/src/features/assistant/data/datasources/assistant_remote_data_source.dart';
import 'package:hero_mart/src/features/assistant/data/repositories/assistant_repository_impl.dart';
import 'package:hero_mart/src/features/assistant/domain/entities/assistant_conversation_entity.dart';

import '../../core/network/network_test_fakes.dart';
import '../../core/storage/cache_test_fakes.dart';
import 'assistant_fixtures.dart';
import 'presentation/assistant_test_fakes.dart';

/// `GET /v1/assistant/conversations` on a scripted transport: the live
/// payload, or no connection once [offline].
class _Server {
  bool offline = false;
  int reads = 0;

  late final FakeHttpClientAdapter adapter = FakeHttpClientAdapter((
    options,
    _,
  ) {
    reads++;
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return okBody(AssistantFixtures.liveResults('conversations_list_en.json'));
  });
}

AssistantRepositoryImpl _repository(
  _Server server, {
  required CacheOwner owner,
  InMemoryJsonCacheStore? store,
}) {
  final dio = Dio()..httpClientAdapter = server.adapter;
  return AssistantRepositoryImpl(
    AssistantRemoteDataSourceImpl(DioConsumer(dio), DioEventStreamClient(dio)),
    cache: AssistantHistoryCacheDataSourceImpl(
      CacheSlots(
        store: store ?? InMemoryJsonCacheStore(),
        owner: owner,
        locale: FakeLocaleProvider('en'),
      ),
    ),
  );
}

AssistantConversationEntity _chat(String id) =>
    AssistantConversationEntity(id: id, title: id);

void main() {
  group('the device copy', () {
    test('the first page paints from it', () async {
      final server = _Server();
      final repository = _repository(
        server,
        owner: CacheOwner()..signedIn('c1'),
      );
      await repository.watchFirstPage(limit: 20).drain<void>();
      await pumpEventQueue();
      server.offline = true;

      final copy = await repository.watchFirstPage(limit: 20).toList();

      expect(copy.single.isFromCache, isTrue);
      expect(copy.single.data.items, hasLength(3));
      expect(server.reads, 1, reason: 'a fresh copy ends the read');
    });

    test('nothing is kept for a guest, nor for a later page', () async {
      final store = InMemoryJsonCacheStore();
      final guest = _repository(
        _Server(),
        owner: CacheOwner()..signedOut(),
        store: store,
      );
      final customer = _repository(
        _Server(),
        owner: CacheOwner()..signedIn('c1'),
        store: store,
      );

      await guest.watchFirstPage(limit: 20).drain<void>();
      await customer.getConversations(page: 2, limit: 20);
      await pumpEventQueue();

      expect(store.writes, 0);
    });
  });

  group('AssistantHistoryCubit', () {
    late FakeAssistantRepository repository;
    setUp(() => repository = FakeAssistantRepository());

    test('a saved history paints at once, marked stale; a failed check '
        'keeps it', () async {
      repository.savedFirstPage = feedOf([_chat('a')]);
      final cubit = historyCubit(repository);
      addTearDown(cubit.close);

      final loading = cubit.load();
      await settle();

      expect(cubit.state.status, LoadPhase.loaded);
      expect(cubit.state.freshness.isStale, isTrue);

      repository.lists.single.open(const Left(NetworkFailure()));
      await loading;

      expect(cubit.state.isLoaded, isTrue);
      expect(cubit.state.feed.items.single.id, 'a');
      expect(cubit.state.freshness.refreshFailed, isTrue);
    });

    test('nothing saved and no connection: the offline state', () async {
      final cubit = historyCubit(repository);
      addTearDown(cubit.close);

      final loading = cubit.load();
      repository.lists.single.open(const Left(NetworkFailure()));
      await loading;

      expect(cubit.state.status, LoadPhase.error);
      expect(cubit.state.failure, isA<NetworkFailure>());
      expect(cubit.state.isSignedOut, isFalse);
    });

    test('reconnect refreshes a saved history once', () async {
      repository.savedFirstPage = feedOf([_chat('a')]);
      final cubit = historyCubit(repository);
      addTearDown(cubit.close);
      final loading = cubit.load();
      await settle();
      repository.lists.single.open(const Left(NetworkFailure()));
      await loading;

      final reconnect = Future.wait([
        cubit.onReconnected(),
        cubit.onReconnected(),
      ]);
      await settle();
      expect(repository.firstPageForced, [false, true]);
      repository.lists.last.open(Right(feedOf([_chat('b'), _chat('a')])));
      await reconnect;

      expect(cubit.state.freshness.isStale, isFalse);
      expect(cubit.state.feed.items.map((chat) => chat.id), ['b', 'a']);
    });

    test('a next page that failed is asked again on reconnect', () async {
      final cubit = historyCubit(repository);
      addTearDown(cubit.close);
      final loading = cubit.load();
      repository.lists.single.open(Right(feedOf([_chat('a')], hasMore: true)));
      await loading;
      final more = cubit.loadMore();
      repository.lists.last.open(const Left(NetworkFailure()));
      await more;
      expect(cubit.state.loadMoreFailed, isTrue);

      final reconnect = cubit.onReconnected();
      await settle();
      expect(repository.lists.last.args, (page: 2, limit: 20));
      repository.lists.last.open(Right(feedOf([_chat('b')], page: 2)));
      await reconnect;

      expect(cubit.state.loadMoreFailed, isFalse);
      expect(cubit.state.feed.items.map((chat) => chat.id), ['a', 'b']);
    });
  });
}
