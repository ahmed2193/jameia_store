import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/usecases/get_account_overview_usecase.dart';

enum AccountStatus { initial, loading, loaded, error }

/// State for the Jameia "Mine" tab (`mach_pro_sailor_c_mine`) — the offline
/// seeded profile (delivery code, avatar) + quick-stat counts + customer-service
/// unread badge. The signed-in customer (name, phone, wallet) comes from the
/// app-global `AuthSessionCubit`, not from here.
class AccountState extends Equatable {
  const AccountState({
    this.status = AccountStatus.initial,
    this.user,
    this.couponCount = 0,
    this.favouriteCount = 0,
    this.customerServiceUnread = 0,
    this.error,
  });

  final AccountStatus status;

  /// Seeded profile; null until the overview has loaded.
  final UserProfileEntity? user;
  final int couponCount;
  final int favouriteCount;
  final int customerServiceUnread;
  final String? error;

  AccountState copyWith({
    AccountStatus? status,
    UserProfileEntity? user,
    int? couponCount,
    int? favouriteCount,
    int? customerServiceUnread,
    String? error,
  }) => AccountState(
    status: status ?? this.status,
    user: user ?? this.user,
    couponCount: couponCount ?? this.couponCount,
    favouriteCount: favouriteCount ?? this.favouriteCount,
    customerServiceUnread: customerServiceUnread ?? this.customerServiceUnread,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    user,
    couponCount,
    favouriteCount,
    customerServiceUnread,
    error,
  ];
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
          favouriteCount: overview.favouriteCount,
          customerServiceUnread: overview.customerServiceUnread,
        ),
      ),
    );
  }
}
