import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/refund_detail.dart';
import '../../domain/repositories/orders_repository.dart';

enum OrderRefundDetailStatus { initial, loading, loaded, error }

/// Page state for the refund progress / detail screen
/// (`mach_pro_sailor_c_order_refund_detail`) — the derived [RefundDetail]
/// resolved through [OrdersRepository].
class OrderRefundDetailState extends Equatable {
  const OrderRefundDetailState({
    this.status = OrderRefundDetailStatus.initial,
    this.refund,
    this.error,
  });

  final OrderRefundDetailStatus status;
  final RefundDetail? refund;
  final String? error;

  OrderRefundDetailState copyWith({
    OrderRefundDetailStatus? status,
    RefundDetail? refund,
    String? error,
  }) =>
      OrderRefundDetailState(
        status: status ?? this.status,
        refund: refund ?? this.refund,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, refund, error];
}

/// Page-scoped cubit — resolved via `sl<OrderRefundDetailCubit>()` and loaded
/// with `..load(orderId)`.
class OrderRefundDetailCubit extends Cubit<OrderRefundDetailState>
    with SafeCubitMixin<OrderRefundDetailState> {
  OrderRefundDetailCubit(this._repository)
      : super(const OrderRefundDetailState());

  final OrdersRepository _repository;

  Future<void> load(String orderId) async {
    safeEmit(state.copyWith(status: OrderRefundDetailStatus.loading));
    final result = await _repository.getRefundDetail(orderId);
    result.fold(
      (failure) => safeEmit(state.copyWith(
        status: OrderRefundDetailStatus.error,
        error: failure.message,
      )),
      (refund) => safeEmit(state.copyWith(
        status: OrderRefundDetailStatus.loaded,
        refund: refund,
      )),
    );
  }
}
