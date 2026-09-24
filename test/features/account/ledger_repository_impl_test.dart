import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/account/data/datasources/loyalty_remote_data_source.dart';
import 'package:jameia_mart/src/features/account/data/datasources/wallet_remote_data_source.dart';
import 'package:jameia_mart/src/features/account/data/models/ledger_page_model.dart';
import 'package:jameia_mart/src/features/account/data/models/loyalty_entry_model.dart';
import 'package:jameia_mart/src/features/account/data/models/loyalty_program_model.dart';
import 'package:jameia_mart/src/features/account/data/models/wallet_entry_model.dart';
import 'package:jameia_mart/src/features/account/data/repositories/loyalty_repository_impl.dart';
import 'package:jameia_mart/src/features/account/data/repositories/wallet_repository_impl.dart';
import 'package:jameia_mart/src/features/account/domain/entities/loyalty_entry_entity.dart';
import 'package:jameia_mart/src/features/account/domain/entities/wallet_entry_entity.dart';

class _FakeWalletRemote implements WalletRemoteDataSource {
  AppException? error;
  final List<(int, int)> calls = [];

  @override
  Future<LedgerPageModel<WalletEntryModel>> getLedger({
    required int page,
    required int limit,
  }) async {
    calls.add((page, limit));
    final failure = error;
    if (failure != null) throw failure;
    return LedgerPageModel<WalletEntryModel>(
      balance: 2750,
      items: [
        WalletEntryModel(
          id: 'w1',
          type: 'cashback',
          amount: 250,
          createdAt: DateTime.utc(2026, 9, 20),
        ),
      ],
      page: page,
      hasMore: true,
    );
  }
}

class _FakeLoyaltyRemote implements LoyaltyRemoteDataSource {
  AppException? error;

  @override
  Future<LedgerPageModel<LoyaltyEntryModel>> getLedger({
    required int page,
    required int limit,
  }) async {
    final failure = error;
    if (failure != null) throw failure;
    return LedgerPageModel<LoyaltyEntryModel>(
      balance: 340,
      items: [
        LoyaltyEntryModel(
          id: 'p1',
          type: 'welcome_bonus',
          pointsDelta: 100,
          createdAt: DateTime.utc(2026, 9, 1),
        ),
      ],
      page: page,
    );
  }

  @override
  Future<LoyaltyProgramModel> getProgram() async {
    final failure = error;
    if (failure != null) throw failure;
    return const LoyaltyProgramModel(enabled: true, profileBonusPoints: 50);
  }
}

void main() {
  group('WalletRepositoryImpl', () {
    test('maps the page to a ledger of entities', () async {
      final remote = _FakeWalletRemote();

      final result = await WalletRepositoryImpl(remote)
          .getLedger(page: 2, limit: 20);

      expect(remote.calls, [(2, 20)]);
      final ledger = result.getOrElse(() => throw StateError('left'));
      expect(ledger.balance, 2750);
      expect(ledger.entries.single.kind, WalletEntryKind.cashback);
      expect(ledger.page, 2);
      expect(ledger.hasMore, isTrue);
    });

    test('401 → UnauthorizedFailure (the sign-in prompt)', () async {
      final remote = _FakeWalletRemote()
        ..error = const UnauthorizedException('Sign in');

      final result = await WalletRepositoryImpl(remote)
          .getLedger(page: 1, limit: 20);

      expect(result, isA<Left<Failure, Object>>());
      expect(result.fold((f) => f, (_) => null), isA<UnauthorizedFailure>());
    });

    test('offline → NetworkFailure', () async {
      final remote = _FakeWalletRemote()
        ..error = const NoInternetConnectionException();

      final result = await WalletRepositoryImpl(remote)
          .getLedger(page: 1, limit: 20);

      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
    });
  });

  group('LoyaltyRepositoryImpl', () {
    test('maps the ledger and the programme', () async {
      final repository = LoyaltyRepositoryImpl(_FakeLoyaltyRemote());

      final ledger = (await repository.getLedger(
        page: 1,
        limit: 20,
      )).getOrElse(() => throw StateError('left'));
      final program = (await repository.getProgram()).getOrElse(
        () => throw StateError('left'),
      );

      expect(ledger.balance, 340);
      expect(ledger.entries.single.kind, LoyaltyEntryKind.welcomeBonus);
      expect(program.enabled, isTrue);
      expect(program.profileBonusPoints, 50);
    });

    test('a broken payload → ParsingFailure', () async {
      final remote = _FakeLoyaltyRemote()..error = const ParsingException();

      final result = await LoyaltyRepositoryImpl(remote).getProgram();

      expect(result.fold((f) => f, (_) => null), isA<ParsingFailure>());
    });
  });
}
