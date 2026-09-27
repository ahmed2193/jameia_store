import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/phone_number.dart';
import '../../domain/usecases/get_welcome_bonus_usecase.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import 'login_state.dart';

/// Page-scoped cubit for the login screen: tracks the typed phone, requests
/// the one-time code and reads the store's welcome offer. The page reacts to
/// [LoginStatus.codeSent] by opening the OTP screen with the challenge.
class LoginCubit extends Cubit<LoginState> with SafeCubitMixin<LoginState> {
  LoginCubit(this._sendOtp, this._getWelcomeBonus) : super(const LoginState());

  final SendOtpUseCase _sendOtp;
  final GetWelcomeBonusUseCase _getWelcomeBonus;

  /// Reads the welcome bonus once per screen. It only decorates the offer
  /// card, so a failure (offline, the store unreachable) keeps the card's
  /// generic words and says nothing.
  Future<void> loadWelcomeBonus() async {
    final result = await _getWelcomeBonus(const NoParams());
    result.fold(
      (failure) =>
          log('welcome bonus unavailable', name: 'LoginCubit', error: failure),
      (points) => safeEmit(state.copyWith(welcomeBonus: points)),
    );
  }

  /// Accepts typed or pasted input; parsing rules live in [PhoneNumber].
  /// The field reports caret moves too: the same number is not an edit, so
  /// it neither resets the status nor drops the challenge.
  void phoneChanged(String raw) {
    final phone = PhoneNumber.parseKuwait(raw);
    if (phone == state.phone) return;
    safeEmit(
      state.copyWith(
        phone: phone,
        status: LoginStatus.initial,
        clearChallenge: true,
      ),
    );
  }

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
