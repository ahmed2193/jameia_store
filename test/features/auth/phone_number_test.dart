import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/features/auth/domain/entities/phone_number.dart';

void main() {
  test('validates 8 ASCII digits and formats E.164 / display', () {
    const phone = PhoneNumber.kuwait('12345678');
    expect(phone.isValid, isTrue);
    expect(phone.e164, '+96512345678');
    expect(phone.display, '+965 12345678');
    expect(const PhoneNumber.kuwait('1234567').isValid, isFalse);
    expect(const PhoneNumber.kuwait('1234567a').isValid, isFalse);
    expect(PhoneNumber.empty.isEmpty, isTrue);
  });

  test('parseKuwait strips separators and country-code prefixes', () {
    expect(PhoneNumber.parseKuwait('+965 1234-5678').localDigits, '12345678');
    expect(PhoneNumber.parseKuwait('00965 12345678').localDigits, '12345678');
    expect(PhoneNumber.parseKuwait('96512345678').localDigits, '12345678');
    expect(PhoneNumber.parseKuwait('965123').localDigits, '965123');
    expect(PhoneNumber.parseKuwait('1234567899').localDigits, '12345678');
    expect(PhoneNumber.parseKuwait('abc').isEmpty, isTrue);
  });
}
