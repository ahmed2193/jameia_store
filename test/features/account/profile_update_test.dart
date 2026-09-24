import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/features/account/data/mappers/profile_update_mapper.dart';
import 'package:jameia_mart/src/features/account/domain/entities/profile_update.dart';

final AuthCustomerEntity _customer = AuthCustomerEntity(
  id: 'x',
  phone: '+96512345678',
  nameEn: 'Ahmed',
  nameAr: 'Ahmed',
  email: 'ahmed@jm3eia.com',
  gender: CustomerGender.male,
  dateOfBirth: DateTime(1990, 5, 17),
  householdSize: 3,
);

/// The sign-up placeholder: the backend names a new customer after the phone.
const AuthCustomerEntity _newCustomer = AuthCustomerEntity(
  id: 'y',
  phone: '+96512345678',
  nameEn: '+96512345678',
  nameAr: '+96512345678',
);

ProfileUpdate _diff({
  AuthCustomerEntity? current,
  String name = 'Ahmed',
  String email = 'ahmed@jm3eia.com',
  CustomerGender? gender = CustomerGender.male,
  DateTime? dateOfBirth,
  bool keepDateOfBirth = true,
  int? householdSize = 3,
}) => ProfileUpdate.diff(
  current: current ?? _customer,
  name: name,
  email: email,
  gender: gender,
  dateOfBirth: keepDateOfBirth
      ? (dateOfBirth ?? DateTime(1990, 5, 17))
      : dateOfBirth,
  householdSize: householdSize,
);

void main() {
  group('ProfileUpdate.diff', () {
    test('is empty when nothing changed (whitespace ignored)', () {
      final update = _diff(name: '  Ahmed ');
      expect(update.isEmpty, isTrue);
      expect(update.toBody(), isEmpty);
    });

    test('carries only the changed fields', () {
      final update = _diff(name: 'Ahmed Ali');
      expect(update.name, 'Ahmed Ali');
      expect(update.email, isNull);
      expect(update.gender, isNull);
      expect(update.toBody(), {'name': 'Ahmed Ali'});
    });

    test('clearing email and gender sends explicit nulls', () {
      final update = _diff(email: '', gender: null);
      expect(update.clearGender, isTrue);
      expect(update.toBody(), {'email': null, 'gender': null});
    });

    test('the same birthday at another time of day is no change', () {
      final update = _diff(dateOfBirth: DateTime(1990, 5, 17, 13, 45));
      expect(update.isEmpty, isTrue);
    });

    test('a new birthday and household size go out in wire format', () {
      final update = _diff(dateOfBirth: DateTime(1991, 1, 2), householdSize: 5);
      expect(update.toBody(), {
        'dateOfBirth': '1991-01-02',
        'householdSize': 5,
      });
    });

    test('removing the birthday and the household size sends nulls', () {
      final update = _diff(keepDateOfBirth: false, householdSize: null);
      expect(update.clearDateOfBirth, isTrue);
      expect(update.clearHouseholdSize, isTrue);
      expect(update.toBody(), {'dateOfBirth': null, 'householdSize': null});
    });

    test('values the customer never had are not "cleared"', () {
      final update = _diff(
        current: _newCustomer,
        name: '',
        email: '',
        gender: null,
        keepDateOfBirth: false,
        householdSize: null,
      );
      expect(update.isEmpty, isTrue);
    });

    test('the phone placeholder is not the name: typing one is a change', () {
      final update = _diff(
        current: _newCustomer,
        name: 'Sara',
        email: '',
        gender: null,
        keepDateOfBirth: false,
        householdSize: null,
      );
      expect(update.toBody(), {'name': 'Sara'});
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

    test('date of birth: from 1900 up to today, never in the future', () {
      final today = DateTime(2026, 9, 21, 8);
      expect(
        ProfileUpdate.isValidDateOfBirth(DateTime(1990), today: today),
        isTrue,
      );
      expect(
        ProfileUpdate.isValidDateOfBirth(DateTime(2026, 9, 21), today: today),
        isTrue,
      );
      expect(
        ProfileUpdate.isValidDateOfBirth(DateTime(2026, 9, 22), today: today),
        isFalse,
      );
      expect(
        ProfileUpdate.isValidDateOfBirth(DateTime(1899, 12, 31), today: today),
        isFalse,
      );
    });

    test('household size: 1–20', () {
      expect(ProfileUpdate.isValidHouseholdSize(1), isTrue);
      expect(ProfileUpdate.isValidHouseholdSize(20), isTrue);
      expect(ProfileUpdate.isValidHouseholdSize(0), isFalse);
      expect(ProfileUpdate.isValidHouseholdSize(21), isFalse);
    });

    test('isSameDay ignores the time and treats two nulls as equal', () {
      expect(
        ProfileUpdate.isSameDay(DateTime(2000, 1, 1, 1), DateTime(2000, 1, 1)),
        isTrue,
      );
      expect(ProfileUpdate.isSameDay(null, null), isTrue);
      expect(ProfileUpdate.isSameDay(DateTime(2000), null), isFalse);
    });
  });
}
