import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/auth/domain/entities/otp_challenge.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/otp_cubit.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/otp_state.dart';

import 'auth_test_fakes.dart';

void main() {
  late FakeSendOtpUseCase sendOtp;
  late FakeVerifyOtpUseCase verifyOtp;

  // A tick that never fires inside a test keeps the countdown out of the
  // bloc_test expectations; the countdown test passes its own fast tick.
  const idleTick = Duration(days: 1);
  final cooldown = OtpCubit.resendCooldown.inSeconds;

  OtpCubit build({String? debugCode = '1234', Duration tick = idleTick}) =>
      OtpCubit(
        sendOtp: sendOtp,
        verifyOtp: verifyOtp,
        phone: kPhone,
        debugCode: debugCode,
        tick: tick,
      );

  setUp(() {
    sendOtp = FakeSendOtpUseCase(const Right(kChallenge));
    verifyOtp = FakeVerifyOtpUseCase(const Right(kCustomer));
  });

  test('starts with the resend cooldown running and the debug code', () async {
    final cubit = build();
    expect(cubit.state.resendSecondsLeft, cooldown);
    expect(cubit.state.canResend, isFalse);
    expect(cubit.state.hasDebugCode, isTrue);
    await cubit.close();
  });

  testWidgets('countdown ticks every second and enables resend at zero', (
    tester,
  ) async {
    final cubit = build(tick: const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 10));
    expect(cubit.state.resendSecondsLeft, cooldown - 10);
    expect(cubit.state.canResend, isFalse);
    await tester.pump(Duration(seconds: cooldown));
    expect(cubit.state.resendSecondsLeft, 0);
    expect(cubit.state.canResend, isTrue);
    await cubit.close();
  });

  test('codeChanged keeps digits and caps at the max length', () async {
    final cubit = build();
    cubit.codeChanged('12a3-4567 89');
    expect(cubit.state.code, '12345678');
    expect(cubit.state.code.length, OtpChallenge.maxCodeLength);
    expect(cubit.state.canVerify, isTrue);
    cubit.codeChanged('12');
    expect(cubit.state.canVerify, isFalse);
    await cubit.close();
  });

  blocTest<OtpCubit, OtpState>(
    'verify → verifying → verified with the customer',
    build: build,
    seed: () => OtpState(phone: kPhone, code: '1234', debugCode: '1234'),
    act: (cubit) => cubit.verify(),
    expect: () => [
      isA<OtpState>().having((s) => s.status, 'status', OtpStatus.verifying),
      isA<OtpState>()
          .having((s) => s.status, 'status', OtpStatus.verified)
          .having((s) => s.customer, 'customer', kCustomer),
    ],
    verify: (_) {
      expect(verifyOtp.calls.single.code, '1234');
      expect(verifyOtp.calls.single.phone, kPhone);
    },
  );

  blocTest<OtpCubit, OtpState>(
    'verify → error keeps the code so the user can fix it',
    build: () {
      verifyOtp.result = const Left(
        ServerFailure(
          'Wrong code',
          statusCode: 400,
          code: 'INVALID_CREDENTIALS',
        ),
      );
      return build();
    },
    seed: () => OtpState(phone: kPhone, code: '9999'),
    act: (cubit) => cubit.verify(),
    expect: () => [
      isA<OtpState>().having((s) => s.status, 'status', OtpStatus.verifying),
      isA<OtpState>()
          .having((s) => s.status, 'status', OtpStatus.error)
          .having((s) => s.failure?.message, 'failure', 'Wrong code')
          .having((s) => s.code, 'code', '9999'),
    ],
  );

  blocTest<OtpCubit, OtpState>(
    'verify is a no-op while the code is incomplete',
    build: build,
    seed: () => OtpState(phone: kPhone, code: '12'),
    act: (cubit) => cubit.verify(),
    expect: () => <OtpState>[],
    verify: (_) => expect(verifyOtp.calls, isEmpty),
  );

  blocTest<OtpCubit, OtpState>(
    'resend after cooldown clears the code, swaps the debug code, restarts',
    build: () {
      sendOtp.result = const Right(
        OtpChallenge(phone: kPhone, message: 'sent', debugCode: '5678'),
      );
      return build();
    },
    seed: () => OtpState(phone: kPhone, code: '1234', debugCode: '1234'),
    act: (cubit) => cubit.resend(),
    expect: () => [
      isA<OtpState>().having((s) => s.isResending, 'isResending', isTrue),
      isA<OtpState>()
          .having((s) => s.isResending, 'isResending', isFalse)
          .having((s) => s.code, 'code', '')
          .having((s) => s.debugCode, 'debugCode', '5678'),
      isA<OtpState>().having(
        (s) => s.resendSecondsLeft,
        'resendSecondsLeft',
        cooldown,
      ),
    ],
    verify: (_) => expect(sendOtp.calls, hasLength(1)),
  );

  blocTest<OtpCubit, OtpState>(
    'resend is blocked while the cooldown runs',
    build: build,
    act: (cubit) => cubit.resend(),
    expect: () => <OtpState>[],
    verify: (_) => expect(sendOtp.calls, isEmpty),
  );
}
