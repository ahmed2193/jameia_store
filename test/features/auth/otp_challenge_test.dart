import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/features/auth/domain/entities/otp_challenge.dart';
import 'package:jameia_mart/src/features/auth/domain/entities/phone_number.dart';

void main() {
  const phone = PhoneNumber.kuwait('12345678');

  test('code completeness follows the documented 4–8 range', () {
    expect(OtpChallenge.isCodeComplete('123'), isFalse);
    expect(OtpChallenge.isCodeComplete('1234'), isTrue);
    expect(OtpChallenge.isCodeComplete('12345678'), isTrue);
    expect(OtpChallenge.isCodeComplete('123456789'), isFalse);
  });

  test('normalizeCode keeps digits only and caps at the max length', () {
    expect(OtpChallenge.normalizeCode('12a3-4567 89'), '12345678');
    expect(OtpChallenge.normalizeCode(' 12 '), '12');
    expect(OtpChallenge.normalizeCode('abc'), '');
  });

  test('hasDebugCode only for a non-empty echoed code', () {
    const withCode = OtpChallenge(phone: phone, message: 'm', debugCode: '1');
    const noCode = OtpChallenge(phone: phone, message: 'm');
    const emptyCode = OtpChallenge(phone: phone, message: 'm', debugCode: '');
    expect(withCode.hasDebugCode, isTrue);
    expect(noCode.hasDebugCode, isFalse);
    expect(emptyCode.hasDebugCode, isFalse);
  });
}
