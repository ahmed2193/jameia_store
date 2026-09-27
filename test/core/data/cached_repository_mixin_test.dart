// CachedRepositoryMixin, every branch of the offline screen contract, over
// the real CacheSlots on an in-memory store: fresh hit → no request; stale
// hit → copy then network (saved); stale hit + failure → copy then failure;
// miss + failure; forceRefresh skips the copy; too old → not shown; a copy
// that no longer parses → miss + deleted; a copy "from the future" → shown
// but revalidated; a reply after the owner changed → not saved; unknown
// owner → no cache at all; a slow write never delays the screen; a
// mutation reply kept as the copy (not after the owner changed). Plus the
// CacheSlots identity rules.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/data/datasources/cache_slots.dart';
import 'package:hero_mart/src/core/data/models/remote_payload.dart';
import 'package:hero_mart/src/core/data/repositories/base_repository_mixin.dart';
import 'package:hero_mart/src/core/data/repositories/cached_repository_mixin.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/storage/cache_key.dart';
import 'package:hero_mart/src/core/storage/cache_namespace.dart';
import 'package:hero_mart/src/core/storage/cache_owner.dart';

import '../network/network_test_fakes.dart';
import '../storage/cache_test_fakes.dart';

/// A tiny DTO: `{ "names": [...] }`, strict like the real ones.
class _NamesModel {
  const _NamesModel(this.names);

  factory _NamesModel.fromJson(Object raw) {
    final names = raw is Map<String, dynamic> ? raw['names'] : null;
    if (names is! List) throw const ParsingException('names missing');
    return _NamesModel(names.cast<String>());
  }

  final List<String> names;
}

class _Repository with BaseRepositoryMixin, CachedRepositoryMixin {
  _Repository(this.slots, this.namespace);

  final CacheSlots slots;
  final CacheNamespace namespace;
  DateTime now = DateTime.utc(2026, 9, 27, 12);
  int fetches = 0;
  Completer<void>? fetchGate;
  Object? fetchError;
  List<String> serverNames = const ['fresh'];

  @override
  DateTime cacheClock() => now;

  Stream<DataSnapshot<List<String>>> watch({bool forceRefresh = false}) =>
      cachedRead(
        cache: slots.of<_NamesModel>(namespace, parse: _NamesModel.fromJson),
        fetch: () async {
          fetches++;
          await fetchGate?.future;
          final error = fetchError;
          if (error != null) throw error;
          final raw = {'names': serverNames};
          return RemotePayload(_NamesModel.fromJson(raw), raw);
        },
        toEntity: (model) => model.names,
        forceRefresh: forceRefresh,
      );
}

/// Collects a read: its snapshots, then its failure (if any).
Future<(List<DataSnapshot<List<String>>>, Failure?)> _collect(
  Stream<DataSnapshot<List<String>>> stream,
) async {
  final snapshots = <DataSnapshot<List<String>>>[];
  Failure? failure;
  final done = Completer<void>();
  stream.listen(
    snapshots.add,
    onError: (Object error) => failure = error as Failure,
    onDone: done.complete,
  );
  await done.future;
  return (snapshots, failure);
}

void main() {
  late InMemoryJsonCacheStore store;
  late CacheOwner owner;
  late FakeLocaleProvider locale;
  late CacheSlots slots;
  late _Repository repository;

  final t0 = DateTime.utc(2026, 9, 27, 12);
  CacheKey keyOf(
    CacheNamespace namespace, {
    String? owner,
    String lang = 'en',
  }) => CacheKey(
    namespace: namespace,
    language: lang,
    owner: owner ?? CacheKey.publicOwner,
  );

  setUp(() {
    store = InMemoryJsonCacheStore();
    owner = CacheOwner();
    locale = FakeLocaleProvider('en');
    slots = CacheSlots(store: store, owner: owner, locale: locale);
    repository = _Repository(slots, testNamespace);
  });

  void seed(List<String> names, {required Duration age}) =>
      store.seed(keyOf(testNamespace), {'names': names}, t0.subtract(age));

  test('fresh hit → the copy, and no request', () async {
    seed(['saved'], age: const Duration(seconds: 30));
    final (snapshots, failure) = await _collect(repository.watch());
    expect(snapshots.map((s) => s.data), [
      ['saved'],
    ]);
    expect(snapshots.single.origin, SnapshotOrigin.cache);
    expect(
      snapshots.single.fetchedAt,
      t0.subtract(const Duration(seconds: 30)),
    );
    expect(failure, isNull);
    expect(repository.fetches, 0);
  });

  test('stale hit → the copy, then the network (saved)', () async {
    seed(['saved'], age: const Duration(minutes: 5));
    final (snapshots, failure) = await _collect(repository.watch());
    expect(snapshots.map((s) => s.origin), [
      SnapshotOrigin.cache,
      SnapshotOrigin.network,
    ]);
    expect(snapshots.last.data, ['fresh']);
    expect(snapshots.last.fetchedAt, t0);
    expect(failure, isNull);
    await pumpEventQueue();
    expect(store.entryOf(keyOf(testNamespace))?.data, {
      'names': ['fresh'],
    });
    expect(store.entryOf(keyOf(testNamespace))?.savedAt, t0);
  });

  test('stale hit + network failure → the copy, then the failure', () async {
    seed(['saved'], age: const Duration(minutes: 5));
    repository.fetchError = const NoInternetConnectionException();
    final (snapshots, failure) = await _collect(repository.watch());
    expect(snapshots.single.data, ['saved']);
    expect(failure, isA<NetworkFailure>());
    expect(store.writes, 0);
  });

  test('miss + failure → the failure only', () async {
    repository.fetchError = const RequestTimeoutException();
    final (snapshots, failure) = await _collect(repository.watch());
    expect(snapshots, isEmpty);
    expect(failure, isA<TimeoutFailure>());
  });

  test('miss + success → the network, saved', () async {
    final (snapshots, _) = await _collect(repository.watch());
    expect(snapshots.single.origin, SnapshotOrigin.network);
    await pumpEventQueue();
    expect(store.writes, 1);
  });

  test(
    'forceRefresh skips the copy (fresh or not) and asks the server',
    () async {
      seed(['saved'], age: const Duration(seconds: 5));
      final (snapshots, _) = await _collect(
        repository.watch(forceRefresh: true),
      );
      expect(store.reads, 0);
      expect(snapshots.single.origin, SnapshotOrigin.network);
      expect(repository.fetches, 1);
    },
  );

  test('a copy past maxAge is never shown', () async {
    seed(['ancient'], age: const Duration(days: 8));
    final (snapshots, _) = await _collect(repository.watch());
    expect(snapshots.single.origin, SnapshotOrigin.network);
  });

  test(
    'a copy that no longer parses → a miss, deleted, then the network',
    () async {
      store.seed(keyOf(testNamespace), {'unexpected': 1}, t0);
      final (snapshots, failure) = await _collect(repository.watch());
      expect(snapshots.single.origin, SnapshotOrigin.network);
      expect(failure, isNull, reason: 'never a parsing error from the cache');
      expect(store.removes, 1);
    },
  );

  test(
    'a copy from the future (clock moved back) is shown but stale',
    () async {
      store.seed(keyOf(testNamespace), {
        'names': ['future'],
      }, t0.add(const Duration(hours: 3)));
      final (snapshots, _) = await _collect(repository.watch());
      expect(snapshots.map((s) => s.origin), [
        SnapshotOrigin.cache,
        SnapshotOrigin.network,
      ]);
    },
  );

  test('the copy always comes before the network', () async {
    seed(['saved'], age: const Duration(minutes: 5));
    store.readGate = Completer<void>();
    final seen = <SnapshotOrigin>[];
    final done = Completer<void>();
    repository.watch().listen((s) => seen.add(s.origin), onDone: done.complete);
    await pumpEventQueue();
    expect(repository.fetches, 0, reason: 'the request waits for the copy');
    store.readGate!.complete();
    await done.future;
    expect(seen, [SnapshotOrigin.cache, SnapshotOrigin.network]);
  });

  test('language is part of the key', () async {
    seed(['english'], age: const Duration(seconds: 5));
    locale.languageCode = 'ar';
    final (snapshots, _) = await _collect(repository.watch());
    expect(snapshots.single.origin, SnapshotOrigin.network);
    await pumpEventQueue();
    expect(store.entryOf(keyOf(testNamespace, lang: 'ar')), isNotNull);
    expect(store.entryOf(keyOf(testNamespace))?.data, {
      'names': ['english'],
    }, reason: 'the English copy stays');
  });

  group('owner-scoped namespaces', () {
    const personal = CacheNamespace(
      'test.personal',
      scope: CacheScope.owner,
      freshFor: Duration(seconds: 60),
      maxAge: Duration(days: 7),
    );
    const mine = CacheNamespace(
      'test.mine',
      scope: CacheScope.customer,
      freshFor: Duration(seconds: 60),
      maxAge: Duration(days: 7),
    );

    test('unknown owner → no cache read, no write', () async {
      repository = _Repository(slots, personal);
      final (snapshots, _) = await _collect(repository.watch());
      expect(snapshots.single.origin, SnapshotOrigin.network);
      await pumpEventQueue();
      expect(store.reads + store.writes, 0);
    });

    test('a guest caches under guest; a customer under their id', () async {
      repository = _Repository(slots, personal);
      owner.signedOut();
      await _collect(repository.watch());
      owner.signedIn('42');
      await _collect(repository.watch());
      await pumpEventQueue();
      expect(
        store.entryOf(keyOf(personal, owner: CacheOwner.guest)),
        isNotNull,
      );
      expect(store.entryOf(keyOf(personal, owner: 'c:42')), isNotNull);
    });

    test('customer-only data is never cached for a guest', () async {
      repository = _Repository(slots, mine);
      owner.signedOut();
      await _collect(repository.watch());
      await pumpEventQueue();
      expect(store.writes, 0);
    });

    test(
      'keepReply saves a mutation reply as the copy, at the clock',
      () async {
        repository = _Repository(slots, mine);
        owner.signedIn('42');
        repository.keepReply(
          slots.of<_NamesModel>(mine, parse: _NamesModel.fromJson),
          {
            'names': ['cancelled'],
          },
        );
        await pumpEventQueue();

        final saved = store.entryOf(keyOf(mine, owner: 'c:42'));
        expect(saved?.data, {
          'names': ['cancelled'],
        });
        expect(saved?.savedAt, repository.now);
      },
    );

    test('keepReply drops a reply taken for an owner who changed', () async {
      repository = _Repository(slots, mine);
      owner.signedIn('42');
      final slot = slots.of<_NamesModel>(mine, parse: _NamesModel.fromJson);
      owner.signedOut();

      repository
        ..keepReply(slot, {
          'names': ['late'],
        })
        ..keepReply(null, {
          'names': ['no slot'],
        });
      await pumpEventQueue();

      expect(store.writes, 0);
    });

    test('a reply that lands after sign-out is not saved', () async {
      repository = _Repository(slots, mine)..fetchGate = Completer<void>();
      owner.signedIn('42');
      final pending = _collect(repository.watch());
      await pumpEventQueue();
      owner.signedOut();
      repository.fetchGate!.complete();
      final (snapshots, _) = await pending;
      expect(snapshots.single.origin, SnapshotOrigin.network);
      await pumpEventQueue();
      expect(store.writes, 0);
    });
  });

  test('a write that never finishes does not delay the screen', () async {
    final stuck = _StuckStore();
    repository = _Repository(
      CacheSlots(store: stuck, owner: owner, locale: locale),
      testNamespace,
    );
    final (snapshots, _) = await _collect(repository.watch());
    expect(snapshots.single.origin, SnapshotOrigin.network);
    expect(stuck.writeStarted, isTrue);
  });
}

/// A store whose writes never complete.
class _StuckStore extends InMemoryJsonCacheStore {
  bool writeStarted = false;

  @override
  Future<void> write(CacheKey key, Object data, {required DateTime savedAt}) {
    writeStarted = true;
    return Completer<void>().future;
  }
}
