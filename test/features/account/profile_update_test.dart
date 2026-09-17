import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/features/account/data/mappers/profile_update_mapper.dart';
import 'package:jameia_mart/src/features/account/domain/entities/profile_update.dart';

const AuthCustomerEntity _customer = AuthCustomerEntity(
  id: 'x',
  phone: '+96512345678',
  nameEn: 'Ahmed',
  nameAr: 'Ahmed',
  email: 'ahmed@jm3eia.com',
  gender: CustomerGender.male,
);

void main() {
  group('ProfileUpdate.diff', () {
    test('is empty when nothing changed (whitespace ignored)', () {
      final update = ProfileUpdate.diff(
        current: _customer,
        name: '  Ahmed ',
        email: 'ahmed@jm3eia.com',
        gender: CustomerGender.male,
      );
      expect(update.isEmpty, isTrue);
      expect(update.toBody(), isEmpty);
    });

    test('carries only the changed fields', () {
      final update = ProfileUpdate.diff(
        current: _customer,
        name: 'Ahmed Ali',
        email: 'ahmed@jm3eia.com',
        gender: CustomerGender.male,
      );
      expect(update.name, 'Ahmed Ali');
      expect(update.email, isNull);
      expect(update.gender, isNull);
      expect(update.toBody(), {'name': 'Ahmed Ali'});
    });

    test('clearing email and gender sends explicit nulls', () {
      final update = ProfileUpdate.diff(
        current: _customer,
        name: 'Ahmed',
        email: '',
        gender: null,
      );
      expect(update.clearGender, isTrue);
      expect(update.toBody(), {'email': null, 'gender': null});
    });

    test('gender + language + date of birth use the wire format', () {
      final body = ProfileUpdate(
        gender: CustomerGender.female,
        language: 'ar',
        dateOfBirth: DateTime(1990, 5, 17),
        householdSize: 3,
      ).toBody();
      expect(body, {
        'gender': 'female',
        'language': 'ar',
        'dateOfBirth': '1990-05-17',
        'householdSize': 3,
      });
    });
  });

  group('validators', () {
    test('name: non-blank, at most 120 chars', () {
      expect(ProfileUpdate.isValidName('Ahmed'), isTrue);
      expect(ProfileUpdate.isValidName('   '), isFalse);
      expect(ProfileUpdate.isValidName('a' * 121), isFalse);
    });

    test('email: basic shape, 3–120 chars', () {
      expect(ProfileUpdate.isValidEmail('a@b.co'), isTrue);
      expect(ProfileUpdate.isValidEmail('nope'), isFalse);
      expect(ProfileUpdate.isValidEmail('a b@c.d'), isFalse);
      expect(ProfileUpdate.isValidEmail('${'a' * 120}@b.co'), isFalse);
    });
  });
}
