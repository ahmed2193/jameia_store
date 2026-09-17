import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/core/data/mappers/customer_mapper.dart';
import 'package:jameia_mart/src/features/auth/data/mappers/otp_challenge_mapper.dart';
import 'package:jameia_mart/src/core/data/models/customer_model.dart';
import 'package:jameia_mart/src/features/auth/data/models/otp_challenge_model.dart';
import 'package:jameia_mart/src/features/auth/domain/entities/otp_challenge.dart';
import 'package:jameia_mart/src/features/auth/domain/entities/phone_number.dart';

void main() {
  group('CustomerModel.fromJson', () {
    test('accepts _id or id and keeps a bilingual name raw', () {
      final mongo = CustomerModel.fromJson({
        '_id': 'abc',
        'phone': '+96512345678',
        'name': {'en': 'Ahmed', 'ar': 'أحمد'},
        'email': 'a@b.c',
      });
      expect(mongo.id, 'abc');
      expect(mongo.nameEn, 'Ahmed');
      expect(mongo.nameAr, 'أحمد');
      expect(mongo.email, 'a@b.c');

      final plain = CustomerModel.fromJson({'id': 'x', 'name': 'Sara'});
      expect(plain.id, 'x');
      expect(plain.nameEn, 'Sara');
      expect(plain.nameAr, 'Sara');
      expect(plain.phone, '');

      final arabicOnly = CustomerModel.fromJson({
        'id': 'y',
        'name': {'ar': 'سارة'},
      });
      expect(arabicOnly.nameEn, '');
      expect(arabicOnly.nameAr, 'سارة');
    });

    test('maps to the core entity; name picks per locale, phone fallback', () {
      const model = CustomerModel(
        id: 'x',
        phone: '+9651',
        nameEn: 'Ahmed',
        nameAr: 'أحمد',
      );
      final entity = model.toEntity();
      expect(
        entity,
        const AuthCustomerEntity(
          id: 'x',
          phone: '+9651',
          nameEn: 'Ahmed',
          nameAr: 'أحمد',
        ),
      );
      expect(entity.displayNameFor('ar'), 'أحمد');
      expect(entity.displayNameFor('en'), 'Ahmed');
      const nameless = CustomerModel(id: 'x', phone: '+9651');
      expect(nameless.toEntity().displayNameFor('en'), '+9651');
    });
  });

  group('OtpChallengeModel', () {
    test('tolerates a numeric echoed code and a missing one', () {
      final numeric = OtpChallengeModel.fromJson({
        'message': 'm',
        'code': 4321,
      });
      expect(numeric.code, '4321');
      expect(OtpChallengeModel.fromJson({'message': 'm'}).code, isNull);
      expect(OtpChallengeModel.fromJson({}).message, '');
    });

    test('maps to OtpChallenge carrying the phone', () {
      const phone = PhoneNumber.kuwait('12345678');
      const model = OtpChallengeModel(message: 'm', code: '1');
      expect(
        model.toEntity(phone),
        const OtpChallenge(phone: phone, message: 'm', debugCode: '1'),
      );
    });
  });
}
