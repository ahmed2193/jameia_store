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
  /// Ignored while the code is being checked or was accepted, and a caret
  /// move (same digits) is not an edit — a refused code stays refused.
  void codeChanged(String raw) {
    if (state.isLocked) return;
    final code = OtpChallenge.normalizeCode(raw);
    if (code == state.code) return;
    safeEmit(
      state.copyWith(
        code: code,
        status: OtpStatus.idle,
        clearCodeFailure: true,
      ),
    );
  }

  Future<void> verify() async {
    if (!state.canVerify) return;
    safeEmit(state.copyWith(status: OtpStatus.verifying));
    final result = await _verifyOtp(
      VerifyOtpParams(phone: state.phone, code: state.code),
    );
    result.fold(
      (failure) {
        final refused = OtpChallenge.isRefusedCode(failure);
        safeEmit(
          state.copyWith(
            status: OtpStatus.error,
            failure: failure,
            codeFailure: refused ? failure : null,
            rejections: refused ? state.rejections + 1 : null,
          ),
        );
      },
      (customer) => safeEmit(
        state.copyWith(status: OtpStatus.verified, customer: customer),
      ),
    );
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    // A new code is on its way: the refusal of the old one no longer applies.
    safeEmit(state.copyWith(isResending: true, clearCodeFailure: true));
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
