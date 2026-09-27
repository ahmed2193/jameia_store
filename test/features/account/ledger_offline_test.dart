// Wallet / points offline: the first page (the balance with it) is kept on
// the device for the signed-in customer, never for a guest; the history
// paints the saved copy marked stale, plays the change when the server's
// answer moved the balance, asks again once on reconnect, and a next page
// that failed waits for the connection (and for a saved page 1 to be
// checked with the server) and is asked again after the reconnect refresh.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/datasources/cache_slots.dart';
import 'package:jameia_mart/src/core/data/models/remote_payload.dart';
import 'package:jameia_mart/src/core/domain/entities/screen_load.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/storage/cache_owner.dart';
import 'package:jameia_mart/src/features/account/data/datasources/ledger_cache_data_source.dart';
import 'package:jameia_mart/src/features/account/data/datasources/wallet_remote_data_source.dart';
import 'package:jameia_mart/src/features/account/data/models/ledger_page_model.dart';
import 'package:jameia_mart/src/features/account/data/models/ledger_results.dart';
import 'package:jameia_mart/src/features/account/data/models/wallet_entry_model.dart';
import 'package:jameia_mart/src/features/account/data/repositories/wallet_repository_impl.dart';
import 'package:jameia_mart/src/features/account/domain/entities/ledger.dart';
import 'package:jameia_mart/src/features/account/domain/entities/wallet_entry_entity.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/ledger_cubit.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/ledger_state.dart';

import '../../core/network/network_test_fakes.dart';
import '../../core/storage/cache_test_fakes.dart';
import 'account_test_fakes.dart';

typedef _Wallet = WalletEntryEntity;

/// `GET /v1/account/wallet` → `results` as the server sends it.
Map<String, Object?> _walletResults() => {
  'balance': {'wallet': 2750},
  'data': [
    {
      '_id': 'w1',
      'type': 'refund',
      'amount': 250,
      'createdAt': '2026-09-20T00:00:00.000Z',
    },
  ],
  'pagination': {'total': 1, 'page': 1, 'limit': 20, 'hasMore': false},
};

class _Remote implements WalletRemoteDataSource {
  Object? error;
  int reads = 0;

  @override
  Future<RemotePayload<LedgerPageModel<WalletEntryModel>>> getLedger({
    required int page,
    required int limit,
  }) async {
    reads++;
    final current = error;
    if (current != null) throw current;
    final raw = _walletResults();
    return RemotePayload(LedgerResults.wallet(raw, page: page), raw);
  }
}

WalletRepositoryImpl _repository(
  _Remote remote,
  CacheOwner owner,
  InMemoryJsonCacheStore store,
) => WalletRepositoryImpl(
  remote,
  cache: LedgerCacheDataSourceImpl(
    CacheSlots(store: store, owner: owner, locale: FakeLocaleProvider('en')),
  ),
);

Ledger<_Wallet> _ledger(
  int balance, {
  int page = 1,
  bool hasMore = false,
  List<String> ids = const ['w1'],
}) => Ledger<_Wallet>(
  balance: balance,
  entries: [
    for (final id in ids)
      WalletEntryEntity(
        id: id,
        kind: WalletEntryKind.refund,
        amountFils: 250,
        createdAt: DateTime(2026, 9, 20),
      ),
  ],
  page: page,
  hasMore: hasMore,
);

LedgerCubit<_Wallet> _cubit(
  FakeGetLedgerUseCase<_Wallet> get, {
  Ledger<_Wallet>? saved,
  List<WatchLedgerFromGet<_Wallet>>? watchOut,
}) {
  final watch = WatchLedgerFromGet<_Wallet>(get, saved: saved);
  watchOut?.add(watch);
  return LedgerCubit<_Wallet>(watch, get);
}

void main() {
  group('the device copy', () {
    test('the first page and its balance paint from it', () async {
      final remote = _Remote();
      final repository = _repository(
        remote,
        CacheOwner()..signedIn('c1'),
        InMemoryJsonCacheStore(),
      );
      await repository.watchFirstPage(limit: 20).drain<void>();
      await pumpEventQueue();
      remote.error = const NoInternetConnectionException();

      final copy = await repository.watchFirstPage(limit: 20).toList();

      expect(copy.single.isFromCache, isTrue);
      expect(copy.single.data.balance, 2750);
      expect(copy.single.data.entries.single.id, 'w1');
      expect(remote.reads, 1, reason: 'a fresh copy ends the read');
    });

    test('nothing is kept for a guest', () async {
      final store = InMemoryJsonCacheStore();
      final repository = _repository(
        _Remote(),
        CacheOwner()..signedOut(),
        store,
      );

      await repository.watchFirstPage(limit: 20).drain<void>();
      await pumpEventQueue();

      expect(store.writes, 0);
    });
  });

  group('LedgerCubit', () {
    test('offline with a saved history: the list, marked stale', () async {
      final get = FakeGetLedgerUseCase<_Wallet>(
        (_) async => const Left(NetworkFailure()),
      );
      final cubit = _cubit(get, saved: _ledger(1000));

      await cubit.load();

      expect(cubit.state.status, LoadPhase.loaded);
      expect(cubit.state.ledger.balance, 1000);
      expect(cubit.state.freshness.isStale, isTrue);
      expect(cubit.state.failure, isA<NetworkFailure>());
      expect(cubit.state.changeSerial, 0, reason: 'nothing moved');
      await cubit.close();
    });

    test(
      'the server answer over the saved copy plays the change once',
      () async {
        final get = FakeGetLedgerUseCase<_Wallet>(
          (_) async => Right(_ledger(1500, ids: ['w2', 'w1'])),
        );
        final cubit = _cubit(get, saved: _ledger(1000));

        await cubit.load();

        expect(cubit.state.ledger.balance, 1500);
        expect(cubit.state.changeSerial, 1);
        expect(cubit.state.change.newEntryIds, {'w2'});
        expect(cubit.state.freshness.isStale, isFalse);
        await cubit.close();
      },
    );

    test('reconnect refreshes a saved history once', () async {
      Either<Failure, Ledger<_Wallet>> answer = const Left(NetworkFailure());
      final get = FakeGetLedgerUseCase<_Wallet>((_) async => answer);
      final watches = <WatchLedgerFromGet<_Wallet>>[];
      final cubit = _cubit(get, saved: _ledger(1000), watchOut: watches);
      await cubit.load();

      answer = Right(_ledger(1000));
      await Future.wait([cubit.onReconnected(), cubit.onReconnected()]);

      expect(watches.single.forced, [false, true]);
      expect(cubit.state.freshness.isStale, isFalse);
      await cubit.close();
    });

    test('a next page that failed is asked again on reconnect', () async {
      final get = FakeGetLedgerUseCase<_Wallet>(
        (params) async => params.page == 1
            ? Right(_ledger(1000, hasMore: true))
            : const Left(NetworkFailure()),
      );
      final cubit = _cubit(get);
      await cubit.load();
      await cubit.loadMore();
      expect(cubit.state.loadMoreFailed, isTrue);

      get.handler = (params) async => Right(
        params.page == 1
            ? _ledger(1000, hasMore: true)
            : _ledger(1000, page: 2, ids: ['w2']),
      );
      await cubit.onReconnected();

      expect(cubit.state.loadMoreFailed, isFalse);
      expect(
        [for (final entry in cubit.state.ledger.entries) entry.id],
        ['w1', 'w2'],
      );
      await cubit.close();
    });

    test('a saved page 1 and a failed next page: the reconnect refreshes '
        'page 1, then asks for the page the footer owes', () async {
      final get = FakeGetLedgerUseCase<_Wallet>(
        (_) async => const Left(NetworkFailure()),
      );
      final cubit = _cubit(get, saved: _ledger(1000, hasMore: true));
      await cubit.load();
      await cubit.loadMore();
      expect(cubit.state.freshness.isStale, isTrue);
      expect(cubit.state.loadMoreFailed, isTrue);

      get.handler = (params) async => Right(
        params.page == 1
            ? _ledger(1000, hasMore: true)
            : _ledger(1000, page: 2, ids: ['w2']),
      );
      await cubit.onReconnected();

      expect(cubit.state.freshness.isStale, isFalse);
      expect(cubit.state.loadMoreFailed, isFalse);
      expect(cubit.state.isLoadingMore, isFalse, reason: 'no dead spinner');
      expect(
        [for (final entry in cubit.state.ledger.entries) entry.id],
        ['w1', 'w2'],
      );
      await cubit.close();
    });

    test('a failed next page is not asked again until a retry', () async {
      final get = FakeGetLedgerUseCase<_Wallet>(
        (params) async => params.page == 1
            ? Right(_ledger(1000, hasMore: true))
            : const Left(NetworkFailure()),
      );
      final cubit = _cubit(get);
      await cubit.load();
      await cubit.loadMore();
      await cubit.loadMore(); // the sentinel built again while offline
      expect(get.calls.where((call) => call.page == 2), hasLength(1));

      await cubit.loadMore(retry: true);
      expect(get.calls.where((call) => call.page == 2), hasLength(2));
      await cubit.close();
    });

    test('a next page asked for while the saved page 1 is being checked '
        'waits for the server, then follows its page 1', () async {
      final page1 = Completer<Either<Failure, Ledger<_Wallet>>>();
      final get = FakeGetLedgerUseCase<_Wallet>(
        (params) => params.page == 1
            ? page1.future
            : Future.value(Right(_ledger(1200, page: 2, ids: ['w2']))),
      );
      final cubit = _cubit(get, saved: _ledger(1000, hasMore: true));
      final loading = cubit.load();
      await pumpEventQueue();
      expect(cubit.state.freshness.fromCache, isTrue);

      await cubit.loadMore();
      expect(
        get.calls.where((call) => call.page == 2),
        isEmpty,
        reason: 'not merged into the copy the server is about to replace',
      );

      page1.complete(Right(_ledger(1200, hasMore: true)));
      await loading;
      await pumpEventQueue();

      expect(get.calls.where((call) => call.page == 2), hasLength(1));
      expect(cubit.state.ledger.balance, 1200);
      expect(
        [for (final entry in cubit.state.ledger.entries) entry.id],
        ['w1', 'w2'],
      );
      await cubit.close();
    });
  });
}
