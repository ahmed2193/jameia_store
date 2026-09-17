import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/coupon.dart';
import '../../domain/usecases/get_coupons_usecase.dart';

enum CouponsStatus { initial, loading, loaded, error }

/// State for the coupon pages — the full coupon set partitioned into the three
/// Jameia tabs (available / used / expired), loaded through [GetCouponsUseCase].
///
/// The same state feeds all three coupon screens (My coupons, Coupon history,
/// Order coupon picker); each reads whichever buckets it renders.
class CouponsState extends Equatable {
  const CouponsState({
    this.status = CouponsStatus.initial,
    this.available = const [],
    this.used = const [],
    this.expired = const [],
    this.error,
  });

  final CouponsStatus status;

  /// Unused, still-valid coupons → "Available" tab / order picker.
  final List<CouponEntity> available;

  /// Coupons already redeemed → "Used" tab / history feed.
  final List<CouponEntity> used;

  /// Lapsed coupons → "Expired" tab / history feed.
  final List<CouponEntity> expired;
  final String? error;

  CouponsState copyWith({
    CouponsStatus? status,
    List<CouponEntity>? available,
    List<CouponEntity>? used,
    List<CouponEntity>? expired,
    String? error,
  }) => CouponsState(
    status: status ?? this.status,
    available: available ?? this.available,
    used: used ?? this.used,
    expired: expired ?? this.expired,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [status, available, used, expired, error];
}

/// Page-scoped cubit — resolved via `sl<CouponsCubit>()`; loads and buckets the
/// coupon list on construction through [GetCouponsUseCase].
class CouponsCubit extends Cubit<CouponsState>
    with SafeCubitMixin<CouponsState> {
  CouponsCubit(this._getCoupons) : super(const CouponsState()) {
    load();
  }

  final GetCouponsUseCase _getCoupons;

  Future<void> load() async {
    safeEmit(state.copyWith(status: CouponsStatus.loading));
    final result = await _getCoupons(const NoParams());
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: CouponsStatus.error, error: failure.message),
      ),
      (buckets) => safeEmit(
        state.copyWith(
          status: CouponsStatus.loaded,
          available: buckets.available,
          used: buckets.used,
          expired: buckets.expired,
        ),
      ),
    );
  }
}
