import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/account_repository.dart';

enum AccountStatus { initial, loading, loaded, error }

/// State for the KeeTa "Mine" tab (`mach_pro_sailor_c_mine`) — profile header +
/// quick-stat counts + customer-service unread badge, loaded through
/// [AccountRepository].
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

  /// Signed-in profile; null until the overview has loaded.
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
  }) =>
      AccountState(
        status: status ?? this.status,
        user: user ?? this.user,
        couponCount: couponCount ?? this.couponCount,
        favouriteCount: favouriteCount ?? this.favouriteCount,
        customerServiceUnread:
            customerServiceUnread ?? this.customerServiceUnread,
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
  AccountCubit(this._repository) : super(const AccountState()) {
    load();
  }

  final AccountRepository _repository;

  Future<void> load() async {
    safeEmit(state.copyWith(status: AccountStatus.loading));
    final result = await _repository.getAccountOverview();
    result.fold(
      (failure) => safeEmit(state.copyWith(
        status: AccountStatus.error,
        error: failure.message,
      )),
      (overview) => safeEmit(state.copyWith(
        status: AccountStatus.loaded,
        user: overview.user,
        couponCount: overview.couponCount,
        favouriteCount: overview.favouriteCount,
        customerServiceUnread: overview.customerServiceUnread,
      )),
    );
  }
}
