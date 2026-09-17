import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import 'login_state.dart';

/// Page-scoped cubit for the login screen: tracks the typed phone and requests
/// the one-time code. The page reacts to [LoginStatus.codeSent] by opening the
/// OTP screen with the challenge.
class LoginCubit extends Cubit<LoginState> with SafeCubitMixin<LoginState> {
  LoginCubit(this._sendOtp) : super(const LoginState());

  final SendOtpUseCase _sendOtp;

  /// Accepts typed or pasted input; parsing rules live in [PhoneNumber].
  void phoneChanged(String raw) => safeEmit(
    state.copyWith(
      phone: PhoneNumber.parseKuwait(raw),
      status: LoginStatus.initial,
      clearChallenge: true,
    ),
  );

  /// Request a code for the typed phone (no-op while invalid or in flight).
  Future<void> submit() async {
    if (!state.canContinue) return;
    safeEmit(state.copyWith(status: LoginStatus.sending));
    final result = await _sendOtp(SendOtpParams(phone: state.phone));
    result.fold(
      (failure) =>
          safeEmit(state.copyWith(status: LoginStatus.error, failure: failure)),
      (challenge) => safeEmit(
        state.copyWith(status: LoginStatus.codeSent, challenge: challenge),
      ),
    );
  }
}
