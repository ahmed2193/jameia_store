import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/data/mappers/customer_mapper.dart';
import 'package:jameia_mart/src/core/data/models/customer_model.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';

void main() {
  group('CustomerModel.fromJson', () {
    test('parses the documented account/me shape', () {
      final model = CustomerModel.fromJson({
        '_id': '507f1f77bcf86cd799439011',
        'name': 'Ahmed',
        'phone': '+96512345678',
        'email': 'ahmed@jm3eia.com',
        'dateOfBirth': '1990-05-17',
        'gender': 'male',
        'householdSize': 4,
        'status': 'active',
        'language': 'ar',
        'wallet': 1250,
        'loyaltyPoints': 320,
        'pro': {
          'active': true,
          'expiresAt': '2027-01-01T00:00:00.000Z',
          'subscriptionId': null,
        },
        'addresses': [],
        'pushTokens': [],
        'marketingPush': false,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      });

      expect(model.id, '507f1f77bcf86cd799439011');
      expect(model.nameEn, 'Ahmed');
      expect(model.nameAr, 'Ahmed');
      expect(model.language, 'ar');
      expect(model.wallet, 1250);
      expect(model.loyaltyPoints, 320);
      expect(model.proActive, isTrue);
      expect(model.proExpiresAt, '2027-01-01T00:00:00.000Z');
      expect(model.dateOfBirth, '1990-05-17');
      expect(model.gender, 'male');
      expect(model.householdSize, 4);
      expect(model.marketingPush, isFalse);
    });

    test('tolerates nulls, a bilingual name and missing optionals', () {
      final model = CustomerModel.fromJson({
        'id': 'x',
        'name': {'en': 'Sara', 'ar': 'سارة'},
        'email': null,
        'gender': null,
        'pro': null,
      });

      expect(model.nameEn, 'Sara');
      expect(model.nameAr, 'سارة');
      expect(model.email, '');
      expect(model.language, '');
      expect(model.wallet, 0);
      expect(model.proActive, isFalse);
      expect(model.gender, isNull);
      expect(model.marketingPush, isTrue);
      expect(model.status, CustomerModel.activeStatus);
    });
  });

  test('a customer without an id is a broken payload', () {
    expect(
      () => CustomerModel.fromJson({'name': 'Nobody', 'phone': '+9651'}),
      throwsA(isA<ParsingException>()),
    );
  });

  group('CustomerMapper', () {
    test('maps money, dates, gender and pro state into the entity', () {
      const model = CustomerModel(
        id: 'x',
        phone: '+9651',
        nameEn: 'Ahmed',
        email: 'a@b.c',
        language: 'en',
        wallet: 1250,
        loyaltyPoints: 10,
        status: 'inactive',
        proActive: true,
        proExpiresAt: '2027-01-01T00:00:00.000Z',
        dateOfBirth: '1990-05-17',
        gender: 'female',
        householdSize: 2,
        marketingPush: false,
      );

      final entity = model.toEntity();

      expect(entity.walletFils, 1250);
      expect(entity.walletKd, 1.25);
      expect(entity.isActive, isFalse);
      expect(entity.isPro, isTrue);
      expect(entity.proExpiresAt, DateTime.utc(2027));
      expect(entity.dateOfBirth, DateTime(1990, 5, 17));
      expect(entity.gender, CustomerGender.female);
      expect(entity.householdSize, 2);
      expect(entity.marketingPush, isFalse);
      expect(entity.hasLanguagePreference, isTrue);
      expect(entity.anyName, 'Ahmed');
      expect(entity.displayNameFor('ar'), 'Ahmed'); // no Arabic → English
    });

    test('unknown gender maps to null; wire values round-trip', () {
      const model = CustomerModel(id: 'x', phone: '+9651', gender: 'other');
      expect(model.toEntity().gender, isNull);
      expect(CustomerGender.male.wireValue, 'male');
      expect(CustomerGender.female.wireValue, 'female');
    });
  });
}
