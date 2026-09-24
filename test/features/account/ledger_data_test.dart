import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/end_points.dart';
import 'package:jameia_mart/src/features/account/data/datasources/loyalty_remote_data_source.dart';
import 'package:jameia_mart/src/features/account/data/datasources/wallet_remote_data_source.dart';
import 'package:jameia_mart/src/features/account/data/mappers/loyalty_mapper.dart';
import 'package:jameia_mart/src/features/account/data/mappers/wallet_mapper.dart';
import 'package:jameia_mart/src/features/account/data/models/loyalty_entry_model.dart';
import 'package:jameia_mart/src/features/account/data/models/loyalty_program_model.dart';
import 'package:jameia_mart/src/features/account/data/models/wallet_entry_model.dart';
import 'package:jameia_mart/src/features/account/domain/entities/loyalty_entry_entity.dart';
import 'package:jameia_mart/src/features/account/domain/entities/wallet_entry_entity.dart';

import '../../core/network/network_test_fakes.dart';

Map<String, Object?> _walletPage({
  List<Object?>? rows,
  bool hasMore = true,
  int page = 1,
}) => {
  'balance': {'wallet': 2750},
  'data':
      rows ??
      [
        {
          '_id': 'w1',
          'customerId': 'c1',
          'type': 'refund',
          'amount': 1250,
          'referenceId': 'o1',
          'note': 'Order #1042',
          'createdAt': '2026-09-20T10:00:00.000Z',
        },
        {
          '_id': 'w2',
          'type': 'checkout',
          'amount': -500,
          'createdAt': '2026-09-19T10:00:00.000Z',
        },
      ],
  'pagination': {'total': 30, 'page': page, 'limit': 20, 'hasMore': hasMore},
};

Map<String, Object?> _loyaltyPage() => {
  'balance': {'loyaltyPoints': 340},
  'data': [
    {
      '_id': 'p1',
      'type': 'earn',
      'pointsDelta': 120,
      'createdAt': '2026-09-20T10:00:00.000Z',
      'expiresAt': '2027-09-20T10:00:00.000Z',
    },
    {
      '_id': 'p2',
      'type': 'profile_bonus',
      'pointsDelta': 50,
      'createdAt': '2026-09-18T10:00:00.000Z',
    },
  ],
  'pagination': {'total': 2, 'page': 1, 'limit': 20, 'hasMore': false},
};

Map<String, Object?> _init({Map<String, Object?>? loyalty}) => {
  'store': {
    'name': 'Jm3eia',
    'loyalty':
        loyalty ??
        {
          'enabled': true,
          'pointsPerKwd': 10,
          'redemptionPerPoint': 1,
          'minRedeemPoints': 500,
          'pointsExpireMonths': 12,
          'welcomeBonusPoints': 100,
          'profileBonusPoints': 50,
        },
  },
};

void main() {
  group('wallet entry', () {
    test('parses a row; unknown kinds map to other', () {
      final entry = WalletEntryModel.fromJson(const {
        '_id': 'w9',
        'type': 'lottery_win',
        'amount': 100,
        'createdAt': '2026-09-20T10:00:00.000Z',
      }).toEntity();
      expect(entry.kind, WalletEntryKind.other);
      expect(entry.amountFils, 100);
      expect(entry.note, isEmpty);
    });

    test('every documented kind has its own case', () {
      const wire = {
        'refund': WalletEntryKind.refund,
        'checkout': WalletEntryKind.checkout,
        'cashback': WalletEntryKind.cashback,
        'admin_adjustment': WalletEntryKind.adminAdjustment,
        'promo': WalletEntryKind.promo,
      };
      for (final MapEntry(key: type, value: kind) in wire.entries) {
        final entry = WalletEntryModel.fromJson({
          'id': 'x',
          'type': type,
          'amount': 1,
          'createdAt': '2026-09-20T10:00:00.000Z',
        }).toEntity();
        expect(entry.kind, kind, reason: type);
      }
    });

    test('a row without an id or a readable date is rejected', () {
      expect(
        () => WalletEntryModel.fromJson(const {
          'type': 'refund',
          'createdAt': '2026-09-20T10:00:00.000Z',
        }),
        throwsA(isA<ParsingException>()),
      );
      expect(
        () => WalletEntryModel.fromJson(const {'_id': 'w', 'createdAt': 'x'}),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('loyalty entry + programme', () {
    test('parses a row with its expiry; unknown kinds map to other', () {
      final entry = LoyaltyEntryModel.fromJson(const {
        '_id': 'p9',
        'type': 'mystery',
        'pointsDelta': -40,
        'createdAt': '2026-09-20T10:00:00.000Z',
        'expiresAt': '2027-09-20T10:00:00.000Z',
      }).toEntity();
      expect(entry.kind, LoyaltyEntryKind.other);
      expect(entry.points, -40);
      expect(entry.isCredit, isFalse);
      expect(entry.expiresAt, DateTime.utc(2027, 9, 20, 10));
    });

    test('the programme comes from store.loyalty of the init snapshot', () {
      final program = LoyaltyProgramModel.fromInitJson(_init()).toEntity();
      expect(program.enabled, isTrue);
      expect(program.pointsPerKwd, 10);
      expect(program.pointValueKd, 0.001);
      expect(program.pointsExpire, isTrue);
      expect(program.profileBonusPoints, 50);
    });

    test('no loyalty block → the programme is off', () {
      final program = LoyaltyProgramModel.fromInitJson(const {
        'store': {'name': 'Jm3eia'},
      }).toEntity();
      expect(program.enabled, isFalse);
      expect(program.profileBonusPoints, 0);
    });
  });

  group('WalletRemoteDataSource', () {
    late FakeHttpClientAdapter adapter;

    WalletRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
      adapter = transport;
      return WalletRemoteDataSourceImpl(
        DioConsumer(Dio()..httpClientAdapter = transport),
      );
    }

    test(
      'GETs /v1/account/wallet with page + limit and parses the page',
      () async {
        final dataSource = build(
          FakeHttpClientAdapter((_, _) => okBody(_walletPage())),
        );

        final page = await dataSource.getLedger(page: 1, limit: 20);

        final request = adapter.requests.single;
        expect(request.method, 'GET');
        expect(request.path, EndPoints.accountWallet);
        expect(request.queryParameters, {'page': 1, 'limit': 20});
        final ledger = page.toEntity();
        expect(ledger.balance, 2750);
        expect(ledger.entries.map((e) => e.id), ['w1', 'w2']);
        expect(ledger.entries.first.note, 'Order #1042');
        expect(ledger.entries.last.amountKd, -0.5);
        expect(ledger.hasMore, isTrue);
        expect(ledger.page, 1);
      },
    );

    test('a malformed row is skipped, the rest of the page kept', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody(
            _walletPage(
              rows: [
                {'type': 'refund'}, // no id, no date
                'not an object',
                {'_id': 'ok', 'amount': 10, 'createdAt': '2026-09-20'},
              ],
            ),
          ),
        ),
      );

      final page = await dataSource.getLedger(page: 1, limit: 20);

      expect(page.items.map((e) => e.id), ['ok']);
    });

    test('401 surfaces as UnauthorizedException', () {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => envelope(
            status: 401,
            statusMessage: 'AUTHENTICATION_REQUIRED',
            errorMessage: 'Sign in to continue',
          ),
        ),
      );

      expect(
        () => dataSource.getLedger(page: 1, limit: 20),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('LoyaltyRemoteDataSource', () {
    late FakeHttpClientAdapter adapter;

    LoyaltyRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
      adapter = transport;
      return LoyaltyRemoteDataSourceImpl(
        DioConsumer(Dio()..httpClientAdapter = transport),
      );
    }

    test('GETs /v1/account/loyalty and reads the points balance', () async {
      final dataSource = build(
        FakeHttpClientAdapter((_, _) => okBody(_loyaltyPage())),
      );

      final ledger = (await dataSource.getLedger(
        page: 2,
        limit: 20,
      )).toEntity();

      expect(adapter.requests.single.path, EndPoints.accountLoyalty);
      expect(adapter.requests.single.queryParameters, {'page': 2, 'limit': 20});
      expect(ledger.balance, 340);
      expect(ledger.entries.map((e) => e.kind), [
        LoyaltyEntryKind.earn,
        LoyaltyEntryKind.profileBonus,
      ]);
      expect(ledger.hasMore, isFalse);
    });

    test(
      'the programme is fetched once per run, even by concurrent callers',
      () async {
        final dataSource = build(
          FakeHttpClientAdapter((_, _) => okBody(_init())),
        );

        final both = await Future.wait([
          dataSource.getProgram(),
          dataSource.getProgram(),
        ]);
        final later = await dataSource.getProgram();

        expect(adapter.requests, hasLength(1));
        expect(adapter.requests.single.path, EndPoints.init);
        expect(identical(both.first, later), isTrue);
      },
    );

    test('a failed programme request is asked again next time', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, call) => call == 0
              ? envelope(
                  status: 500,
                  statusMessage: 'INTERNAL_ERROR',
                  errorMessage: 'boom',
                )
              : okBody(_init()),
        ),
      );

      await expectLater(
        dataSource.getProgram(),
        throwsA(isA<ServerException>()),
      );
      final program = await dataSource.getProgram();

      expect(adapter.requests, hasLength(2));
      expect(program.enabled, isTrue);
    });
  });
}
