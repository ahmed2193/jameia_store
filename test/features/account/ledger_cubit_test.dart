import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/account/domain/entities/ledger.dart';
import 'package:jameia_mart/src/features/account/domain/entities/loyalty_program.dart';
import 'package:jameia_mart/src/features/account/domain/entities/wallet_entry_entity.dart';
import 'package:jameia_mart/src/features/account/domain/usecases/get_ledger_usecase.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/ledger_cubit.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/ledger_state.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/loyalty_program_cubit.dart';

import 'account_test_fakes.dart';

typedef _Wallet = WalletEntryEntity;

_Wallet _entry(String id) => WalletEntryEntity(
  id: id,
  kind: WalletEntryKind.refund,
  amountFils: 100,
  createdAt: DateTime(2026, 9, 20),
);

Ledger<_Wallet> _page(
  int page,
  List<String> ids, {
  bool hasMore = true,
  int balance = 1000,
}) => Ledger<_Wallet>(
  balance: balance,
  entries: [for (final id in ids) _entry(id)],
  page: page,
  hasMore: hasMore,
);

Future<Either<Failure, Ledger<_Wallet>>> _ok(Ledger<_Wallet> ledger) async =>
    Right(ledger);

void main() {
  late FakeGetLedgerUseCase<_Wallet> getLedger;

  LedgerCubit<_Wallet> build() => LedgerCubit<_Wallet>(getLedger);

  setUp(() {
    getLedger = FakeGetLedgerUseCase<_Wallet>(
      (params) => _ok(_page(params.page, ['p${params.page}'])),
    );
  });

  group('load', () {
    blocTest<LedgerCubit<_Wallet>, LedgerState<_Wallet>>(
      'loading → loaded with page 1',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        LedgerState<_Wallet>(status: LedgerStatus.loading),
        LedgerState<_Wallet>(
          status: LedgerStatus.loaded,
          ledger: _page(1, ['p1']),
        ),
      ],
      verify: (_) => expect(getLedger.calls, [
        const GetLedgerParams(page: 1, limit: LedgerCubit.pageSize),
      ]),
    );

    blocTest<LedgerCubit<_Wallet>, LedgerState<_Wallet>>(
      '401 → error that reads as signed out',
      build: () {
        getLedger.handler = (_) async => const Left(UnauthorizedFailure());
        return build();
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.status, LedgerStatus.error);
        expect(cubit.state.isSignedOut, isTrue);
        expect(cubit.state.failedAction, LedgerAction.load);
      },
    );

    blocTest<LedgerCubit<_Wallet>, LedgerState<_Wallet>>(
      'offline → plain error (retry), not the sign-in prompt',
      build: () {
        getLedger.handler = (_) async => const Left(NetworkFailure());
        return build();
      },
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.status, LedgerStatus.error);
        expect(cubit.state.isSignedOut, isFalse);
        expect(cubit.state.failure, isA<NetworkFailure>());
      },
    );
  });

  group('refresh', () {
    blocTest<LedgerCubit<_Wallet>, LedgerState<_Wallet>>(
      'replaces the list with the new page 1',
      build: build,
      act: (cubit) async {
        await cubit.load();
        getLedger.handler = (_) => _ok(_page(1, ['new'], balance: 1500));
        await cubit.refresh();
      },
      verify: (cubit) {
        expect(cubit.state.ledger.entries.map((e) => e.id), ['new']);
        expect(cubit.state.ledger.balance, 1500);
      },
    );

    blocTest<LedgerCubit<_Wallet>, LedgerState<_Wallet>>(
      'a failed refresh keeps the list and reports the failure',
      build: build,
      act: (cubit) async {
        await cubit.load();
        getLedger.handler = (_) async => const Left(TimeoutFailure());
        await cubit.refresh();
      },
      verify: (cubit) {
        expect(cubit.state.status, LedgerStatus.loaded);
        expect(cubit.state.ledger.entries.map((e) => e.id), ['p1']);
        expect(cubit.state.failure, isA<TimeoutFailure>());
        expect(cubit.state.failedAction, LedgerAction.refresh);
      },
    );
  });

  group('loadMore', () {
    blocTest<LedgerCubit<_Wallet>, LedgerState<_Wallet>>(
      'appends the next page',
      build: build,
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
      },
      verify: (cubit) {
        expect(cubit.state.ledger.entries.map((e) => e.id), ['p1', 'p2']);
        expect(cubit.state.ledger.page, 2);
        expect(cubit.state.isLoadingMore, isFalse);
        expect(getLedger.calls.last.page, 2);
      },
    );

    blocTest<LedgerCubit<_Wallet>, LedgerState<_Wallet>>(
      'no request before the first load or when the server has no more',
      build: () {
        getLedger.handler = (params) =>
            _ok(_page(params.page, ['only'], hasMore: false));
        return build();
      },
      act: (cubit) async {
        await cubit.loadMore(); // before load
        await cubit.load();
        await cubit.loadMore(); // hasMore == false
      },
      verify: (_) => expect(getLedger.calls, hasLength(1)),
    );

    test('a second call while one is in flight is ignored', () async {
      final gate = Completer<void>();
      final cubit = build();
      await cubit.load();
      getLedger.handler = (params) async {
        await gate.future;
        return Right(_page(params.page, ['p${params.page}']));
      };

      final first = cubit.loadMore();
      await cubit.loadMore();
      gate.complete();
      await first;

      expect(getLedger.calls.where((c) => c.page == 2), hasLength(1));
      expect(cubit.state.ledger.entries.map((e) => e.id), ['p1', 'p2']);
      await cubit.close();
    });

    blocTest<LedgerCubit<_Wallet>, LedgerState<_Wallet>>(
      'a failed next page keeps the list and offers a retry',
      build: build,
      act: (cubit) async {
        await cubit.load();
        getLedger.handler = (_) async => const Left(NetworkFailure());
        await cubit.loadMore();
      },
      verify: (cubit) {
        expect(cubit.state.ledger.entries.map((e) => e.id), ['p1']);
        expect(cubit.state.loadMoreFailed, isTrue);
        expect(cubit.state.isLoadingMore, isFalse);
        expect(cubit.state.failedAction, LedgerAction.loadMore);
      },
    );

    test('a next page that lands after a refresh is dropped', () async {
      final gate = Completer<void>();
      final cubit = build();
      await cubit.load();
      getLedger.handler = (params) async {
        await gate.future;
        return Right(_page(params.page, ['stale']));
      };
      final more = cubit.loadMore(); // page 2 of the OLD list, held

      getLedger.handler = (_) => _ok(_page(1, ['fresh']));
      await cubit.refresh();
      gate.complete();
      await more;

      expect(cubit.state.ledger.entries.map((e) => e.id), ['fresh']);
      expect(cubit.state.isLoadingMore, isFalse);
      await cubit.close();
    });

    test('a stale next page never clears the flag of a newer one', () async {
      final staleGate = Completer<void>();
      final newGate = Completer<void>();
      final cubit = build();
      await cubit.load();
      getLedger.handler = (params) async {
        await staleGate.future;
        return Right(_page(params.page, ['stale']));
      };
      final stale = cubit.loadMore();

      getLedger.handler = (_) => _ok(_page(1, ['fresh']));
      await cubit.refresh(); // resets the paging: a new next page may start
      getLedger.handler = (params) async {
        await newGate.future;
        return Right(_page(params.page, ['next']));
      };
      final newer = cubit.loadMore();
      expect(cubit.state.isLoadingMore, isTrue);

      staleGate.complete();
      await stale;
      expect(cubit.state.isLoadingMore, isTrue, reason: 'still in flight');
      await cubit.loadMore(); // guarded: no third request
      expect(getLedger.calls.where((c) => c.page == 2), hasLength(2));

      newGate.complete();
      await newer;
      expect(cubit.state.ledger.entries.map((e) => e.id), ['fresh', 'next']);
      expect(cubit.state.isLoadingMore, isFalse);
      await cubit.close();
    });
  });

  group('LoyaltyProgramCubit', () {
    const program = LoyaltyProgram(enabled: true, profileBonusPoints: 50);

    blocTest<LoyaltyProgramCubit, LoyaltyProgram>(
      'emits the programme',
      build: () => LoyaltyProgramCubit(
        FakeGetLoyaltyProgramUseCase(const Right(program)),
      ),
      act: (cubit) => cubit.load(),
      expect: () => [program],
    );

    blocTest<LoyaltyProgramCubit, LoyaltyProgram>(
      'a failure leaves "no programme" (the screen shows none of it)',
      build: () => LoyaltyProgramCubit(
        FakeGetLoyaltyProgramUseCase(const Left(NetworkFailure())),
      ),
      act: (cubit) => cubit.load(),
      expect: () => <LoyaltyProgram>[],
      verify: (cubit) => expect(cubit.state, LoyaltyProgram.none),
    );
  });
}
