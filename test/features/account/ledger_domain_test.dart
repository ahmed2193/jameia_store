import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/features/account/domain/entities/ledger.dart';
import 'package:jameia_mart/src/features/account/domain/entities/loyalty_program.dart';
import 'package:jameia_mart/src/features/account/domain/entities/wallet_entry_entity.dart';

WalletEntryEntity _entry(String id, {int amount = 100}) => WalletEntryEntity(
  id: id,
  kind: WalletEntryKind.refund,
  amountFils: amount,
  createdAt: DateTime(2026, 9, 20),
);

AuthCustomerEntity _customer({
  int points = 0,
  DateTime? dateOfBirth,
  CustomerGender? gender,
  int? householdSize,
}) => AuthCustomerEntity(
  id: 'c',
  phone: '+96512345678',
  nameEn: 'Sara',
  nameAr: 'Sara',
  loyaltyPoints: points,
  dateOfBirth: dateOfBirth,
  gender: gender,
  householdSize: householdSize,
);

const LoyaltyProgram _program = LoyaltyProgram(
  enabled: true,
  pointsPerKwd: 10,
  redemptionPerPoint: 5,
  profileBonusPoints: 50,
);

void main() {
  group('Ledger', () {
    test('empty has nothing loaded yet', () {
      const ledger = Ledger<WalletEntryEntity>.empty();
      expect(ledger.isEmpty, isTrue);
      expect(ledger.page, 0);
      expect(ledger.hasMore, isFalse);
    });

    test(
      'merge appends the next page, drops repeats, keeps the newer balance',
      () {
        final first = Ledger<WalletEntryEntity>(
          balance: 1000,
          entries: [_entry('a'), _entry('b')],
          page: 1,
          hasMore: true,
        );
        final next = Ledger<WalletEntryEntity>(
          balance: 1100, // a line was added meanwhile and shifted the pages
          entries: [_entry('b'), _entry('c')],
          page: 2,
          hasMore: false,
        );

        final merged = first.merge(next);

        expect(merged.entries.map((e) => e.id), ['a', 'b', 'c']);
        expect(merged.balance, 1100);
        expect(merged.page, 2);
        expect(merged.hasMore, isFalse);
      },
    );
  });

  group('WalletEntryEntity', () {
    test('signed fils in dinar', () {
      expect(_entry('a', amount: -1250).amountKd, -1.25);
      expect(_entry('a', amount: -1250).isCredit, isFalse);
      expect(WalletEntryEntity.kdOf(2750), 2.75);
    });
  });

  group('LoyaltyProgram', () {
    test('what points are worth', () {
      expect(_program.pointValueKd, 0.005);
      expect(_program.valueKdOf(200), 1.0);
      expect(LoyaltyProgram.none.valueKdOf(200), 0);
    });

    test(
      'the profile bonus is offered only while the details are incomplete',
      () {
        expect(_program.profileBonusFor(_customer()), 50);
        expect(
          _program.profileBonusFor(
            _customer(
              dateOfBirth: DateTime(1990),
              gender: CustomerGender.female,
              householdSize: 2,
            ),
          ),
          0,
        );
        expect(LoyaltyProgram.none.profileBonusFor(_customer()), 0);
        expect(
          const LoyaltyProgram(profileBonusPoints: 50)
              .profileBonusFor(_customer()),
          0,
          reason: 'programme switched off',
        );
      },
    );

    test('a save that completes the details reports the points it earned', () {
      final complete = _customer(
        points: 150,
        dateOfBirth: DateTime(1990),
        gender: CustomerGender.male,
        householdSize: 4,
      );
      expect(
        LoyaltyProgram.profileBonusEarned(
          before: _customer(points: 100),
          after: complete,
        ),
        50,
      );
      expect(
        LoyaltyProgram.profileBonusEarned(before: complete, after: complete),
        0,
        reason: 'already complete before',
      );
      expect(
        LoyaltyProgram.profileBonusEarned(
          before: _customer(points: 100),
          after: _customer(points: 150, gender: CustomerGender.male),
        ),
        0,
        reason: 'still incomplete after',
      );
      expect(
        LoyaltyProgram.profileBonusEarned(
          before: _customer(points: 150),
          after: complete,
        ),
        0,
        reason: 'no points credited',
      );
    });
  });
}
