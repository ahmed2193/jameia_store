import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/keeta_repository.dart';

/// Page-scoped cubit for the KeeTa `passport_login` screen. Tracks the typed
/// phone number and exposes whether the Continue CTA is enabled. Dummy data
/// only — submit/social are no-ops over the in-memory [KeetaRepository].
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._repo) : super(const LoginState());

  // ignore: unused_field — kept for parity with the page-scoped cubit pattern.
  final KeetaRepository _repo;

  void phoneChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    emit(state.copyWith(phone: digits));
  }

  void submit() {
    if (!state.canContinue) return;
    // Dummy data: no real auth call; navigation is driven by the screen.
  }

  void continueWithSocial() {
    // Dummy data: social sign-in is a no-op stub.
  }
}

class LoginState extends Equatable {
  const LoginState({this.phone = ''});

  final String phone;

  /// Kuwait mobile numbers are 8 digits.
  bool get canContinue => phone.length == 8;

  LoginState copyWith({String? phone}) =>
      LoginState(phone: phone ?? this.phone);

  @override
  List<Object?> get props => [phone];
}
