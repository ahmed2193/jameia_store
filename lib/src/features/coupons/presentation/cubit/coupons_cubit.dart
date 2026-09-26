import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_coupons_usecase.dart';
import 'coupons_state.dart';

/// Page-scoped cubit behind the three coupon screens. The page calls [load]
/// (the constructor does not); the error view's retry calls it again.
class CouponsCubit extends Cubit<CouponsState>
    with SafeCubitMixin<CouponsState> {
  CouponsCubit(this._getCoupons) : super(const CouponsState());

  final GetCouponsUseCase _getCoupons;

  Future<void> load() async {
    if (state.status == CouponsStatus.loading) return;
    safeEmit(state.copyWith(status: CouponsStatus.loading));
    final result = await _getCoupons(const NoParams());
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: CouponsStatus.error, failure: failure),
      ),
      (buckets) => safeEmit(
        state.copyWith(status: CouponsStatus.loaded, buckets: buckets),
      ),
    );
  }
}
