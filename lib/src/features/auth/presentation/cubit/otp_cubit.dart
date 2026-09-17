import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/otp_challenge.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import 'otp_state.dart';

/// Page-scoped cubit for the OTP screen: verifies the typed code, resends a
/// new one after the cooldown, and owns the countdown timer.
class OtpCubit extends Cubit<OtpState> with SafeCubitMixin<OtpState> {
  OtpCubit({
    required this._sendOtp,
    required this._verifyOtp,
    required PhoneNumber phone,
    String? debugCode,
    this._tick = AppConstants.tick,
  }) : super(OtpState(phone: phone, debugCode: debugCode)) {
    _startCountdown();
  }

  /// Business timer (not motion): how long "Resend" stays disabled.
  static const Duration resendCooldown = Duration(seconds: 60);

  final SendOtpUseCase _sendOtp;
  final VerifyOtpUseCase _verifyOtp;
  final Duration _tick;
  Timer? _countdown;

  /// Accepts typed or pasted input; the rules live in [OtpChallenge].
  void codeChanged(String raw) => safeEmit(
    state.copyWith(
      code: OtpChallenge.normalizeCode(raw),
      status: OtpStatus.idle,
    ),
  );

  Future<void> verify() async {
    if (!state.canVerify) return;
    safeEmit(state.copyWith(status: OtpStatus.verifying));
    final result = await _verifyOtp(
      VerifyOtpParams(phone: state.phone, code: state.code),
    );
    result.fold(
      (failure) =>
          safeEmit(state.copyWith(status: OtpStatus.error, failure: failure)),
      (customer) => safeEmit(
        state.copyWith(status: OtpStatus.verified, customer: customer),
      ),
    );
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    safeEmit(state.copyWith(isResending: true));
    final result = await _sendOtp(SendOtpParams(phone: state.phone));
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          isResending: false,
          status: OtpStatus.error,
          failure: failure,
        ),
      ),
      (challenge) {
        safeEmit(
          state.copyWith(
            isResending: false,
            status: OtpStatus.idle,
            code: '',
            debugCode: challenge.debugCode,
          ),
        );
        _startCountdown();
      },
    );
  }

  void _startCountdown() {
    _countdown?.cancel();
    safeEmit(state.copyWith(resendSecondsLeft: resendCooldown.inSeconds));
    _countdown = Timer.periodic(_tick, (timer) {
      final left = state.resendSecondsLeft - 1;
      if (left <= 0) timer.cancel();
      safeEmit(state.copyWith(resendSecondsLeft: left < 0 ? 0 : left));
    });
  }

  @override
  Future<void> close() {
    _countdown?.cancel();
    return super.close();
  }
}
