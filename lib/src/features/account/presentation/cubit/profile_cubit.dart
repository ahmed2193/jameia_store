import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/loyalty_program.dart';
import '../../domain/entities/profile_update.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import 'profile_state.dart';

/// Edit-profile form: loads the live customer, holds the draft (name, email,
/// date of birth, gender, household size), saves the diff through
/// `PATCH /v1/account/profile`.
///
/// Page-scoped (`registerFactoryParam`): pass the customer the app already
/// knows so the form renders instantly; [load] refreshes it when the page
/// asks (the session's copy was not confirmed by the server yet).
class ProfileCubit extends Cubit<ProfileState>
    with SafeCubitMixin<ProfileState> {
  ProfileCubit({
    required this._getProfile,
    required this._updateProfile,
    AuthCustomerEntity? initial,
  }) : super(
         initial == null
             ? const ProfileState()
             : ProfileState.fromCustomer(initial),
       );

  final GetProfileUseCase _getProfile;
  final UpdateProfileUseCase _updateProfile;

  /// Fetches the live record. The draft is only (re)seeded while the user
  /// has not typed anything yet, so a slow response never overwrites edits.
  Future<void> load() async {
    if (state.customer == null) {
      safeEmit(state.copyWith(status: ProfileStatus.loading));
    }
    final result = await _getProfile(const NoParams());
    // A refresh that lands while a save is in flight must not touch the state:
    // flipping `saving` back to `ready` would re-enable the button (duplicate
    // PATCH) and swap the diff base mid-save. The save reply is fresher anyway.
    if (state.isSaving) return;
    result.fold(
      (failure) => safeEmit(
        state.copyWith(
          status: state.customer == null
              ? ProfileStatus.error
              : ProfileStatus.ready,
          failure: failure,
        ),
      ),
      (customer) => safeEmit(
        state.isDirty
            ? state.copyWith(status: ProfileStatus.ready, customer: customer)
            : ProfileState.fromCustomer(customer),
      ),
    );
  }

  void nameChanged(String value) => safeEmit(state.copyWith(name: value));

  void emailChanged(String value) => safeEmit(state.copyWith(email: value));

  void genderChanged(CustomerGender? value) =>
      safeEmit(state.copyWith(gender: value, clearGender: value == null));

  /// `null` removes the date of birth.
  void dateOfBirthChanged(DateTime? value) => safeEmit(
    state.copyWith(dateOfBirth: value, clearDateOfBirth: value == null),
  );

  /// One more person (up to the backend's maximum); from "not set" it
  /// starts at one.
  void addPerson() {
    final size = state.householdSize ?? 0;
    if (size >= ProfileUpdate.maxHouseholdSize) return;
    safeEmit(state.copyWith(householdSize: size + 1));
  }

  /// One person less; below the minimum the value is removed.
  void removePerson() {
    final size = state.householdSize;
    if (size == null) return;
    safeEmit(
      size <= ProfileUpdate.minHouseholdSize
          ? state.copyWith(clearHouseholdSize: true)
          : state.copyWith(householdSize: size - 1),
    );
  }

  Future<void> save() async {
    if (state.isSaving) return;
    if (!state.isValid) {
      safeEmit(state.copyWith(showErrors: true));
      return;
    }
    final before = state.customer;
    if (!state.canSave || before == null) return;
    safeEmit(state.copyWith(status: ProfileStatus.saving));
    final result = await _updateProfile(UpdateProfileParams(state.update));
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: ProfileStatus.error, failure: failure),
      ),
      (customer) => safeEmit(
        ProfileState.fromCustomer(customer).copyWith(
          status: ProfileStatus.saved,
          bonusEarned: LoyaltyProgram.profileBonusEarned(
            before: before,
            after: customer,
          ),
        ),
      ),
    );
  }
}
