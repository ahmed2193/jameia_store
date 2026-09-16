import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/repositories/auth_repository.dart';

enum LoginStatus { initial, submitting, success, error }

/// State for the KeeTa `passport_login` screen — the typed phone number plus the
/// submit status. `canContinue` gates the primary CTA.
class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.phone = '',
    this.error,
  });

  final LoginStatus status;
  final String phone;
  final String? error;

  /// Kuwait mobile numbers are 8 digits.
  bool get canContinue => phone.length == 8;

  LoginState copyWith({LoginStatus? status, String? phone, String? error}) =>
      LoginState(
        status: status ?? this.status,
        phone: phone ?? this.phone,
        error: error,
      );

  @override
  List<Object?> get props => [status, phone, error];
}

/// Page-scoped cubit for the login screen — resolved via `sl<LoginCubit>()`.
/// Tracks the typed phone and calls [AuthRepository.login] on submit / social
/// sign-in (an offline no-op that always succeeds).
class LoginCubit extends Cubit<LoginState> with SafeCubitMixin<LoginState> {
  LoginCubit(this._repository) : super(const LoginState());

  final AuthRepository _repository;

  void phoneChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    safeEmit(state.copyWith(phone: digits));
  }

  /// Continue with the typed phone number (gated by [LoginState.canContinue]).
  Future<void> submit() async {
    if (!state.canContinue) return;
    await _signIn(state.phone);
  }

  /// Continue with a social provider — no phone required.
  Future<void> continueWithSocial() => _signIn(state.phone);

  Future<void> _signIn(String phone) async {
    safeEmit(state.copyWith(status: LoginStatus.submitting));
    final result = await _repository.login(phone);
    result.fold(
      (failure) => safeEmit(state.copyWith(
        status: LoginStatus.error,
        error: failure.message,
      )),
      (_) => safeEmit(state.copyWith(status: LoginStatus.success)),
    );
  }
}
