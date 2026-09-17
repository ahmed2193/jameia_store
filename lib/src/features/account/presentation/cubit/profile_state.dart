import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/profile_update.dart';

enum ProfileStatus { initial, loading, ready, saving, saved, error }

/// Edit-profile form state: the last known [customer] plus the draft fields.
/// Validation rules come from `ProfileUpdate` (domain); the widgets only
/// read the booleans here.
class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.customer,
    this.name = '',
    this.email = '',
    this.gender,
    this.showErrors = false,
    this.failure,
  });

  /// Seeds the draft from a customer already known to the app (instant form,
  /// refreshed from the server afterwards).
  factory ProfileState.fromCustomer(AuthCustomerEntity customer) =>
      ProfileState(
        status: ProfileStatus.ready,
        customer: customer,
        name: customer.anyName,
        email: customer.email,
        gender: customer.gender,
      );

  final ProfileStatus status;
  final AuthCustomerEntity? customer;
  final String name;
  final String email;
  final CustomerGender? gender;

  /// Set after a failed submit so the fields show their inline errors.
  final bool showErrors;

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  bool get isNameValid => ProfileUpdate.isValidName(name);

  /// Email is optional; when given it must look like an address.
  bool get isEmailValid =>
      email.trim().isEmpty || ProfileUpdate.isValidEmail(email);

  bool get isValid => isNameValid && isEmailValid;

  bool get showNameError => showErrors && !isNameValid;

  bool get showEmailError => showErrors && !isEmailValid;

  /// The changes the form holds against the last known customer.
  ProfileUpdate get update {
    final current = customer;
    if (current == null) return const ProfileUpdate();
    return ProfileUpdate.diff(
      current: current,
      name: name,
      email: email,
      gender: gender,
    );
  }

  bool get isDirty => !update.isEmpty;

  bool get isSaving => status == ProfileStatus.saving;

  /// The load failed because nobody is signed in (deep link, expired
  /// session) — the page offers sign-in instead of a retry.
  bool get isSignedOut => customer == null && failure is UnauthorizedFailure;

  bool get canSave => customer != null && !isSaving && isDirty;

  ProfileState copyWith({
    ProfileStatus? status,
    AuthCustomerEntity? customer,
    String? name,
    String? email,
    CustomerGender? gender,
    bool clearGender = false,
    bool? showErrors,
    Failure? failure,
  }) => ProfileState(
    status: status ?? this.status,
    customer: customer ?? this.customer,
    name: name ?? this.name,
    email: email ?? this.email,
    gender: clearGender ? null : (gender ?? this.gender),
    showErrors: showErrors ?? this.showErrors,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    customer,
    name,
    email,
    gender,
    showErrors,
    failure,
  ];
}
