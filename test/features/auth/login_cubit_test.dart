import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/auth/domain/entities/phone_number.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/login_cubit.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/login_state.dart';

import 'auth_test_fakes.dart';

void main() {
  late FakeSendOtpUseCase sendOtp;

  setUp(() => sendOtp = FakeSendOtpUseCase(const Right(kChallenge)));

  test(
    'phoneChanged parses pasted input (prefix, separators) and caps at 8',
    () {
      final cubit = LoginCubit(sendOtp);
      cubit.phoneChanged('+965 1234-5678 99');
      expect(cubit.state.phone, const PhoneNumber.kuwait('12345678'));
      expect(cubit.state.canContinue, isTrue);
      expect(cubit.state.showPhoneError, isFalse);
      cubit.phoneChanged('1234');
      expect(cubit.state.canContinue, isFalse);
      expect(cubit.state.showPhoneError, isTrue);
    },
  );

  blocTest<LoginCubit, LoginState>(
    'submit is a no-op while the phone is invalid',
    build: () => LoginCubit(sendOtp),
    act: (cubit) => cubit
      ..phoneChanged('123')
      ..submit(),
    expect: () => [const LoginState(phone: PhoneNumber.kuwait('123'))],
    verify: (_) => expect(sendOtp.calls, isEmpty),
  );

  blocTest<LoginCubit, LoginState>(
    'submit → sending → codeSent with the challenge',
    build: () => LoginCubit(sendOtp),
    seed: () => const LoginState(phone: kPhone),
    act: (cubit) => cubit.submit(),
    expect: () => [
      const LoginState(phone: kPhone, status: LoginStatus.sending),
      const LoginState(
        phone: kPhone,
        status: LoginStatus.codeSent,
        challenge: kChallenge,
      ),
    ],
    verify: (_) => expect(sendOtp.calls.single.phone, kPhone),
  );

  blocTest<LoginCubit, LoginState>(
    'submit → error with the backend message',
    build: () {
      sendOtp.result = const Left(
        ServerFailure(
          'Too many attempts',
          statusCode: 429,
          code: 'RATE_LIMITED',
        ),
      );
      return LoginCubit(sendOtp);
    },
    seed: () => const LoginState(phone: kPhone),
    act: (cubit) => cubit.submit(),
    expect: () => [
      const LoginState(phone: kPhone, status: LoginStatus.sending),
      const LoginState(
        phone: kPhone,
        status: LoginStatus.error,
        failure: ServerFailure(
          'Too many attempts',
          statusCode: 429,
          code: 'RATE_LIMITED',
        ),
      ),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'editing the phone after codeSent resets the status and drops the challenge',
    build: () => LoginCubit(sendOtp),
    seed: () => const LoginState(
      phone: kPhone,
      status: LoginStatus.codeSent,
      challenge: kChallenge,
    ),
    act: (cubit) => cubit.phoneChanged('1234567'),
    expect: () => [
      const LoginState(
        phone: PhoneNumber.kuwait('1234567'),
        status: LoginStatus.initial,
      ),
    ],
  );
}
