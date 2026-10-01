import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/usecases/get_account_overview_usecase.dart';

enum AccountStatus { initial, loading, loaded, error }

/// State for the Hero "Mine" tab (`mach_pro_sailor_c_mine`) — the offline
/// seeded profile (delivery code, avatar) + the coupons quick-stat count. The signed-in customer (name, phone, wallet) comes from the
/// app-global `AuthSessionCubit`, not from here.
class AccountState extends Equatable {
  const AccountState({
    this.status = AccountStatus.initial,
    this.user,
    this.couponCount = 0,
    this.error,
  });

  final AccountStatus status;

  /// Seeded profile; null until the overview has loaded.
  final UserProfileEntity? user;
  final int couponCount;
  final String? error;

  /// The overview read has answered (loaded or failed) — the Mine tab shows
  /// once this is true, so its counts never flip from zero on open.
  bool get isResolved =>
      status == AccountStatus.loaded || status == AccountStatus.error;

  AccountState copyWith({
    AccountStatus? status,
    UserProfileEntity? user,
    int? couponCount,
    String? error,
  }) => AccountState(
    status: status ?? this.status,
    user: user ?? this.user,
    couponCount: couponCount ?? this.couponCount,
    error: error,
  );

  @override
  List<Object?> get props => [status, user, couponCount, error];
}

/// Page-scoped cubit — resolved via `sl<AccountCubit>()`; loads the overview on
/// construction.
class AccountCubit extends Cubit<AccountState>
    with SafeCubitMixin<AccountState> {
  AccountCubit(this._getOverview) : super(const AccountState()) {
    load();
  }

  final GetAccountOverviewUseCase _getOverview;

  Future<void> load() async {
    safeEmit(state.copyWith(status: AccountStatus.loading));
    final result = await _getOverview(const NoParams());
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: AccountStatus.error, error: failure.message),
      ),
      (overview) => safeEmit(
        state.copyWith(
          status: AccountStatus.loaded,
          user: overview.user,
          couponCount: overview.couponCount,
        ),
      ),
    );
  }
}
